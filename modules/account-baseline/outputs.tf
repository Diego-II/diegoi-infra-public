output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "deploy_role_arn" {
  description = "Set this as role-to-assume in the project's GitHub Actions workflow."
  value       = aws_iam_role.deploy.arn
}

output "state_bucket" {
  description = "The project's own Terraform state bucket (lives in its own account)."
  value       = aws_s3_bucket.tfstate.id
}
