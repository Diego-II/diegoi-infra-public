output "account_id" {
  value = module.baseline.account_id
}

output "deploy_role_arn" {
  description = "Set this as role-to-assume in the project repo's GitHub Actions workflow."
  value       = module.baseline.deploy_role_arn
}

output "state_bucket" {
  description = "project-b's own Terraform state bucket."
  value       = module.baseline.state_bucket
}

output "zone_name" {
  description = "Delegated subdomain. The project repo looks the zone up by name."
  value       = aws_route53_zone.this.name
}

output "zone_id" {
  value = aws_route53_zone.this.zone_id
}

output "zone_name_servers" {
  description = "Written into the parent zone automatically; shown for debugging delegation."
  value       = aws_route53_zone.this.name_servers
}
