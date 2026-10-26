output "parameter_names" {
  description = "The /<app>/<KEY> parameter names created (fill these via put-parameter)."
  value       = [for p in aws_ssm_parameter.secret : p.name]
}

output "parameter_arns" {
  value = [for p in aws_ssm_parameter.secret : p.arn]
}
