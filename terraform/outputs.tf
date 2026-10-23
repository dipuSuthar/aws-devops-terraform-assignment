output "app_url" {
  value = "https://${local.fqdn}"
}
output "alb_dns_name" {
  value = aws_lb.app.dns_name
}
output "rds_endpoint" {
  value = aws_db_instance.main.address
}
output "db_secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}
