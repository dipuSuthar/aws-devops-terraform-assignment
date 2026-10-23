variable "region" {
  type    = string
  default = "ap-south-1"
}
variable "project" {
  type    = string
  default = "devops-task"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "domain_name" {
  description = "Existing Route53 public hosted zone, e.g. example.com"
  type        = string
}
variable "app_subdomain" {
  type    = string
  default = "app"
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "asg_min" {
  type    = number
  default = 2
}
variable "asg_max" {
  type    = number
  default = 4
}
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "db_multi_az" {
  description = "Set true for full HA (costs more)"
  type        = bool
  default     = false
}
