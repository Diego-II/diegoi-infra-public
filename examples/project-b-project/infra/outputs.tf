output "account_id" {
  value = var.aws_account_id
}

output "data_bucket" {
  description = "Bucket holding scraped/raw data."
  value       = aws_s3_bucket.data.id
}
