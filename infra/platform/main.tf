# NETWORK MODULE

module "network" {
  source = "../modules/network"

  name                 = var.name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# ALB SECURITY GROUP

resource "aws_security_group" "alb_sg" {
  name        = "${var.name}-alb-sg"
  description = "Allow HTTP traffic from internet"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-alb-sg"
  }
}

# ECS SECURITY GROUP

resource "aws_security_group" "ecs_sg" {
  name        = "${var.name}-ecs-sg"
  description = "Allow traffic only from ALB"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "Traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-ecs-sg"
  }
}

# RDS SECURITY GROUP

resource "aws_security_group" "rds_sg" {
  name        = "${var.name}-rds-sg"
  description = "Allow PostgreSQL only from ECS"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-rds-sg"
  }
}

# RDS MODULE

module "rds" {
  source = "../modules/rds"

  name                   = var.name
  subnet_ids             = module.network.private_subnet_ids
  security_group_id      = aws_security_group.rds_sg.id
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  max_allocated_storage  = var.db_max_allocated_storage
  backup_retention       = var.db_backup_retention
  deletion_protection    = var.db_deletion_protection
  skip_final_snapshot    = var.db_skip_final_snapshot
  db_name                = var.db_name
  db_username            = var.db_username
}

# ECS MODULE

module "ecs" {
  source = "../modules/ecs"

  name              = var.name
  vpc_id            = module.network.vpc_id
  public_subnets    = module.network.public_subnet_ids
  private_subnets   = module.network.private_subnet_ids

  alb_sg_id         = aws_security_group.alb_sg.id
  ecs_sg_id         = aws_security_group.ecs_sg.id

  app_image         = var.app_image
  container_port    = var.container_port
  cpu               = var.ecs_cpu
  memory            = var.ecs_memory
  desired_count     = var.desired_count

  db_endpoint       = module.rds.db_endpoint
  db_name           = var.db_name
  db_username       = var.db_username
}
