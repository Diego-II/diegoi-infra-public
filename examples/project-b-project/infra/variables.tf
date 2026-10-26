variable "aws_region" {
  description = "Region for all resources in this stack."
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "The project-b account. Guards against applying into the wrong account."
  type        = string
  default     = "333333333333"
}

variable "data_bucket_name" {
  description = "Bucket for scraped/raw government data. Must be globally unique."
  type        = string
  default     = "project-b-data-333333333333"
}
