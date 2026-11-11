aws_region = "ap-south-2"

name = "myapp-dev"

vpc_cidr = "10.10.0.0/16"

public_subnet_cidrs = [
  "10.10.1.0/24",
  "10.10.2.0/24"
]

private_subnet_cidrs = [
  "10.10.3.0/24",
  "10.10.4.0/24"
]

# Application

app_image      = "nginx:1.27-alpine"
container_port = 80

# ECS

ecs_cpu       = 256
ecs_memory    = 512
desired_count = 1

# RDS

db_instance_class        = "db.t3.micro"
db_allocated_storage     = 20
db_max_allocated_storage = 50

db_backup_retention = 1

db_deletion_protection = false
db_skip_final_snapshot = true

db_name     = "appdb"
db_username = "appadmin"
