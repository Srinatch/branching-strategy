output "rds_endpoints" {
  value = {
    for db in aws_db_instance.rds :
    db.id => db.endpoint
  }
}