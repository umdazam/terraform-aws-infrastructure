output "alb_url" {
  description = "Application Load Balancer URL"

  value = "http://${module.platform.alb_dns_name}"
}

output "ecs_cluster_name" {
  value = module.platform.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.platform.ecs_service_name
}

output "rds_endpoint" {
  value = module.platform.rds_endpoint
}

output "rds_secret_arn" {
  value     = module.platform.rds_secret_arn
  sensitive = true
}

output "vpc_id" {
  value = module.platform.vpc_id
}
