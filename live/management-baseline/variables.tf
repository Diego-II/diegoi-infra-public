variable "alert_email" {
  description = "Where budget alerts are sent."
  type        = string
  default     = "owner@example.com"
}

variable "monthly_budget_usd" {
  description = "Org-wide monthly cost budget ceiling in USD."
  type        = string
  default     = "50"
}

variable "alert_thresholds_usd" {
  description = "Absolute USD spend levels at which to send budget alerts (on actual spend)."
  type        = list(number)
  default     = [15, 20]
}

variable "infra_github_owner" {
  description = "Owner of THIS infra repo (for CI OIDC trust)."
  type        = string
  default     = "Diego-II"
}

variable "infra_github_repo" {
  description = "Name of THIS infra repo."
  type        = string
  default     = "diegoi-infra"
}

variable "app_d_table_prefix" {
  description = "DynamoDB table-name prefix the app-d role may manage in the root account. Change if your table is named differently."
  type        = string
  default     = "app-d"
}

variable "enable_org_cloudtrail" {
  description = "Create an organization-wide CloudTrail. Off by default to keep the first apply light; turn on when ready."
  type        = bool
  default     = false
}
