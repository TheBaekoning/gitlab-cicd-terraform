variable "vpc_id" {
  description = "non-prod VPC located in us-east-2 - *******-nonprod-vpc"
  default     = "vpc-******"
}

variable "environment" {
  description = "environment"
  default     = "qa"
}

variable "alb-sg" {
  default = "sg-*****"
}

variable "alb-to-container-sg" {
  default = "sg-******"
}
