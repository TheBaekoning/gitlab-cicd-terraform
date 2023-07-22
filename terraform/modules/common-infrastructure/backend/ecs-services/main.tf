resource "aws_ecr_repository" "service-ecr" {
  name                 = "${var.service-name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_task_definition" "service-task-definition" {
  family = "${var.service-name}-${var.environment}-task-definition"
  container_definitions = jsonencode([
    {
      name      = "${var.service-name}-${var.environment}"
      image     = "*****.dkr.ecr.${var.region}.amazonaws.com/${var.service-name}-${var.environment}:latest"
      cpu       = 0
      essential = true
      portMappings = [
        {
          name = "spring-boot-port"
          containerPort = var.host-port
          hostPort      = var.host-port
          appProtocol = "http"
          protocol = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-create-group  = "true",
          awslogs-group         = "/ecs/${var.service-name}-${var.environment}-task-definition",
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  task_role_arn            = "arn:aws:iam::******:role/ecsTaskExecutionRole"
  execution_role_arn       = "arn:aws:iam::******:role/ecsTaskExecutionRole"
  cpu                      = "1024"
  memory                   = "3072"

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

####################



############## Service

resource "aws_lb_target_group" "service-ip-target" {
  name        = "${var.service-name}-${var.environment}-target-group"
  port        = var.assigned-port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc-id
  health_check {
    enabled = true
    interval = 180
    matcher = "200-299"
    path = "/api/health"
  }
}

resource "aws_lb_listener" "lb_listener_http" {
  load_balancer_arn    = var.alb-arn
  port                 = var.assigned-port
  protocol             = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.service-ip-target.arn
    type             = "forward"
  }
}

resource "aws_ecs_service" "service" {
  name            = "${var.service-name}-${var.environment}"
  cluster         = var.cluster-arn
  task_definition = aws_ecs_task_definition.service-task-definition.arn
  desired_count   = 1
  launch_type = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    subnets = var.subnets
    security_groups = var.container-sg
  }

  force_new_deployment = true

  health_check_grace_period_seconds = 480

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service-ip-target.arn
    container_name   = "${var.service-name}-${var.environment}"
    container_port   = var.host-port
  }
}
