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

variable "alb_name" {
  type = "string"
}

variable "alb_ssl_cert_arn" {
  type = "string"
}

variable "snapshot_flag" {
  type = "string"
  default = "true"
}

variable "snapshot_creation" {
  type = "string"
  default = "6h"
}

variable "snapshot_retention" {
  type = "string"
  default = "24h"
}

variable "user" {
  type = "string"
  default = "ubuntu"
}

variable "role_list" {
  type = "list"
  default = ["controlplane","worker","etcd"]
}

variable "ignore_docker_version" {
  type = "string"
  default = "true"
}

