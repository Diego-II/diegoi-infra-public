output "permission_set_arn" {
  value = aws_ssoadmin_permission_set.admin.arn
}

output "sso_user_id" {
  value = aws_identitystore_user.diego.user_id
}
