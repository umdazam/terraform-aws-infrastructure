output "db_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "db_identifier" {
  value = aws_db_instance.postgres.identifier
}

output "secret_arn" {
  value = aws_db_instance.postgres.master_user_secret[0].secret_arn
}
