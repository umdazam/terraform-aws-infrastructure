aws_region = "ap-south-2"

name = "myapp-prod"

vpc_cidr = "10.20.0.0/16"

public_subnet_cidrs = [
  "10.20.1.0/24",
  "10.20.2.0/24"
]

private_subnet_cidrs = [
  "10.20.3.0/24",
  "10.20.4.0/24"
]

# Application

app_image      = "nginx:1.27-alpine"
container_port = 80

# ECS

ecs_cpu       = 512
ecs_memory    = 1024
desired_count = 2

# RDS

db_instance_class        = "db.t3.small"
db_allocated_storage     = 50
db_max_allocated_storage = 200

db_backup_retention = 14

db_deletion_protection = true
db_skip_final_snapshot = false

db_name     = "appdb"
db_username = "appadmin"
