variable "project_name" {
  description = "Project / account short name, e.g. project-a."
  type        = string
}

variable "github_owner" {
  description = "GitHub owner that hosts the project repo (your personal account)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name that deploys into this account."
  type        = string
}

variable "github_subject_filters" {
  description = "Allowed OIDC `sub` patterns. Default: any ref/branch/PR of the repo."
  type        = list(string)
  default     = null
}

variable "deploy_policy_arns" {
  description = "Managed policies attached to the CI deploy role. Start broad, scope down later."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
