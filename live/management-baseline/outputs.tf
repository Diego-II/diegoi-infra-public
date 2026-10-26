output "infra_ci_role_arn" {
  description = "role-to-assume for this repo's GitHub Actions workflow."
  value       = aws_iam_role.infra_ci.arn
}

output "app_d_deploy_role_arn" {
  description = "role-to-assume for Diego-II/app-d GitHub Actions."
  value       = module.app_d_deploy_role.role_arn
}
