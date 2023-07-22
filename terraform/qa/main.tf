terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  region = "us-east-2"
}

provider "aws" {
  region = local.region
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

############# Subnets #############

data "aws_subnet" "nonprod-subnet-private-main" {
  id     = "subnet-******"
  vpc_id = var.vpc_id
}

data "aws_subnet" "nonprod-subnet-private-secondary" {
  id     = "subnet-*****"
  vpc_id = var.vpc_id
}

data "aws_subnet" "nonprod-subnet-public" {
  id     = "subnet-*****"
  vpc_id = var.vpc_id
}

data "aws_security_group" "alb-sg" {
  id     = var.alb-sg
  vpc_id = var.vpc_id
}

data "aws_security_group" "alb-container-sg" {
  id     = var.alb-to-container-sg
  vpc_id = var.vpc_id
}

##################################

############## MODULES ##################

#module "common-ecs" {
#  source = "../modules/common-infrastructure/backend/ecs-services"
#}
#

resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${var.environment}-backend-ecs-cluster"
}

module "qa-ecs-alb" {
  source              = "../modules/common-infrastructure/backend/alb"
  alb-security-groups = [var.alb-sg]
  alb-subnets         = [data.aws_subnet.*****-nonprod-subnet-private-main.id, data.aws_subnet.********-nonprod-subnet-private-secondary.id]
  environment         = var.environment
}

module "users-qa" {
  source = "../modules/common-infrastructure/backend/ecs-services"

  environment           = var.environment
  host-port             = 8080
  service-name          = "users"
  cluster-arn           = aws_ecs_cluster.ecs-cluster.arn
  assigned-port         = 80
  vpc-id                = var.vpc_id
  subnets               = [data.aws_subnet.*****-nonprod-subnet-private-main.id]
  container-sg          = [data.aws_security_group.alb-container-sg.id]
  alb-arn               = module.qa-ecs-alb.alb-arn
  region = local.region
}

module "optimize-qa" {
  source = "../modules/common-infrastructure/backend/ecs-services"

  environment           = var.environment
  host-port             = 8088
  service-name          = "optimize"
  cluster-arn           = aws_ecs_cluster.ecs-cluster.arn
  assigned-port         = 81
  vpc-id                = var.vpc_id
  subnets               = [data.aws_subnet.******-nonprod-subnet-private-main.id]
  container-sg          = [data.aws_security_group.alb-container-sg.id]
  alb-arn               = module.qa-ecs-alb.alb-arn
  region = local.region
}
