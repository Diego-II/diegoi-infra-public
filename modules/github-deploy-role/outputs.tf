output "role_arn" {
  description = "Set this as role-to-assume in the repo's GitHub Actions workflow."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  value = aws_iam_role.this.name
}
