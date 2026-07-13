resource "aws_db_instance" "rds" {

  for_each = var.rds_instances

  identifier        = each.key
  allocated_storage = each.value.storage
  engine            = "mysql"
  instance_class    = each.value.instance_class

  db_name  = each.value.db_name
  username = var.db_username
  password = var.db_password

  skip_final_snapshot = true
}