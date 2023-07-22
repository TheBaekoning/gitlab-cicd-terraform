resource "aws_s3_bucket" "aws-lb-access-logs" {
  "bucket" = "SOMECOMPANY-aws-lb-${var.environment}-access-logs"

  tags = {
    Name        = "alb-access-logs"
    Environment = var.environment
  }
}

resource "aws_lb" "ecs-backend-alb" {
  name                   = "${var.environment}-backend-alb"
  internal               = true
  load_balancer_type     = "application"
  security_groups        = var.alb-security-groups
  subnets                = var.alb-subnets
  ip_address_type        = "ipv4"
  desync_mitigation_mode = "defensive"

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.aws-lb-access-logs.id
    prefix  = "${var.environment}-alb"
    enabled = false
  }

  tags = {
    Environment = var.environment
  }
}

output "alb-arn" {
  value = aws_lb.ecs-backend-alb.arn
}
