variable "name" {
  description = "IAM role name."
  type        = string
}

variable "github_owner" {
  description = "GitHub owner of the repo allowed to assume the role."
  type        = string
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the role."
  type        = string
}

variable "subject_filters" {
  description = "Allowed OIDC `sub` patterns. Default: any ref/branch/PR of the repo."
  type        = list(string)
  default     = null
}

variable "policy_arns" {
  description = "Managed policy ARNs to attach."
  type        = list(string)
  default     = []
}

variable "inlapp1_policy_json" {
  description = "Optional inline policy JSON (use for tightly-scoped, resource-level permissions)."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
