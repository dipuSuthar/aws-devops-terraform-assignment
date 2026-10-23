resource "random_password" "db" {
  length  = 24
  special = false # avoids characters that break connection strings
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-db"
  subnet_ids = aws_subnet.db[*].id
}

resource "aws_db_instance" "main" {
  identifier                 = "${local.name}-mysql"
  engine                     = "mysql"
  engine_version             = "8.0"
  instance_class             = var.db_instance_class
  allocated_storage          = 20
  max_allocated_storage      = 50
  storage_type               = "gp3"
  storage_encrypted          = true
  db_name                    = "appdb"
  username                   = "appadmin"
  password                   = random_password.db.result
  db_subnet_group_name       = aws_db_subnet_group.main.name
  vpc_security_group_ids     = [aws_security_group.db.id]
  publicly_accessible        = false
  multi_az                   = var.db_multi_az
  backup_retention_period    = 7
  auto_minor_version_upgrade = true
  deletion_protection        = false # assessment only; enable in production
  skip_final_snapshot        = true  # assessment only; set false in production
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${local.name}/db-credentials"
  recovery_window_in_days = 0 # lets you destroy/recreate quickly during the assessment
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = aws_db_instance.main.username
    password = random_password.db.result
    host     = aws_db_instance.main.address
    port     = 3306
    dbname   = aws_db_instance.main.db_name
  })
}
