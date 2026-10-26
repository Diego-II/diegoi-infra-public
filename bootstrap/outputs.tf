output "state_bucket" {
  description = "Name of the Terraform state bucket. Use this in each live/* backend block."
  value       = aws_s3_bucket.tfstate.id
}
