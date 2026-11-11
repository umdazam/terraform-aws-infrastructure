provider "aws" {
  region = var.aws_region
}

module "platform" {
  source = "../../platform"

  name     = var.name
  vpc_cidr = var.vpc_cidr

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  app_image      = var.app_image
  container_port = var.container_port

  ecs_cpu       = var.ecs_cpu
  ecs_memory    = var.ecs_memory
  desired_count = var.desired_count

  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  db_backup_retention      = var.db_backup_retention
  db_deletion_protection   = var.db_deletion_protection
  db_skip_final_snapshot   = var.db_skip_final_snapshot

  db_name     = var.db_name
  db_username = var.db_username
}
