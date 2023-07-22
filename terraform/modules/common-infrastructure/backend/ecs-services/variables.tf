variable "cluster-arn" {}
variable "service-name" {}
variable "environment" {}
variable "host-port" {
  type = number
}
variable "assigned-port" {
  type = number
}
variable "vpc-id" {}
variable "subnets" {
  type = list(string)
}
variable "container-sg" {
  type = list(string)
}
variable "alb-arn" {}
variable "region" {}
