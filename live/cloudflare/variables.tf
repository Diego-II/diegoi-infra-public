variable "account_id" {
  description = "Cloudflare account ID (not secret)."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "owner_emails" {
  description = "Google accounts allowed on the *.example.com catch-all (hosts not listed in apps.yaml)."
  type        = list(string)
  default     = ["owner@example.com"]
}

variable "team_name" {
  description = "Zero Trust team name (<team>.cloudflareaccess.com)."
  type        = string
  default     = "my-org"
}
