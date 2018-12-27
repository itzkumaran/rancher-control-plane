variable "instance_name" {
  type = "string"
  default = "rancher-control-plane"
}

variable "instance_count" {
  type = "string"
  default = "3"
}

variable "instance_type" {
  type = "string"
  default = "t3.medium"
}

variable "key_name" {
  type = "string"
}

variable "ami_id" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "resource_owner" {
  type = "string"
}

variable "resource_domain" {
  type = "string"
}

variable "environment" {
  type = "string"
  default = "dev"
}

