db_password = "MyPassword123"

rds_instances = {
  rds1 = {
    db_name        = "appdb"
    instance_class = "db.t3.micro"
    storage        = 20
  }
}


3 RDS
---------------------------------------
#db_password = "MyPassword123"

#rds_instances = {

#  app-db = {
    db_name        = "appdb"
    instance_class = "db.t3.micro"
    storage        = 20
  }

  user-db = {
    db_name        = "userdb"
    instance_class = "db.t3.small"
    storage        = 30
  }

  log-db = {
    db_name        = "logdb"
    instance_class = "db.t3.micro"
    storage        = 25
  }
}