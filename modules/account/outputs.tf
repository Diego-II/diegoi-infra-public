output "account_id" {
  description = "The new account's 12-digit id."
  value       = aws_organizations_account.this.id
}

output "account_arn" {
  value = aws_organizations_account.this.arn
}

output "org_access_role_arn" {
  description = "Role the tenant stack assumes to manage resources inside the account."
  value       = "arn:aws:iam::${aws_organizations_account.this.id}:role/OrganizationAccountAccessRole"
}
