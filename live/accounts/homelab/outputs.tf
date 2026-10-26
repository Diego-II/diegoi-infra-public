output "account_id" {
  value = module.baseline.account_id
}

output "state_bucket" {
  description = "homelab's own Terraform state bucket."
  value       = module.baseline.state_bucket
}

output "app4_parameter_names" {
  description = "SSM params to fill via `aws ssm put-parameter --overwrite`."
  value       = module.app4_secrets.parameter_names
}

output "winbox_access_key_id" {
  description = "Put on the box as AWS_ACCESS_KEY_ID."
  value       = aws_iam_access_key.winbox.id
}

output "winbox_secret_access_key" {
  description = "Put on the box as AWS_SECRET_ACCESS_KEY. Retrieve: terraform output -raw winbox_secret_access_key"
  value       = aws_iam_access_key.winbox.secret
  sensitive   = true
}
