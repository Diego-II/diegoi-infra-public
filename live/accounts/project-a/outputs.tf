output "account_id" {
  value = module.baseline.account_id
}

output "deploy_role_arn" {
  description = "Put this in Diego-II/project-a's GitHub Actions workflow as role-to-assume."
  value       = module.baseline.deploy_role_arn
}

output "state_bucket" {
  description = "project-a's own Terraform state bucket (in its own account)."
  value       = module.baseline.state_bucket
}
