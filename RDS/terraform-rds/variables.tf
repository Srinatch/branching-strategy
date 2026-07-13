variable "aws_region" {
  default = "ap-south-1"
}

variable "rds_instances" {
  description = "Map of RDS instances"
  type = map(object({
    db_name        = string
    instance_class = string
    storage        = number
  }))
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  sensitive = true
}