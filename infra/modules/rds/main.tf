# RDS SUBNET GROUP

resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.name}-db-subnet-group"
  }
}

# RDS POSTGRESQL INSTANCE

resource "aws_db_instance" "postgres" {
  identifier = "${var.name}-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username

  # AWS manages the master password in Secrets Manager.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]

  publicly_accessible = false

  multi_az = false

  backup_retention_period = var.backup_retention

  backup_window      = "18:00-19:00"
  maintenance_window = "Sun:19:00-Sun:20:00"

  deletion_protection = var.deletion_protection

  skip_final_snapshot = var.skip_final_snapshot

  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"

  auto_minor_version_upgrade = true

  copy_tags_to_snapshot = true

  tags = {
    Name        = "${var.name}-postgres"
    Environment = var.name
  }
}
