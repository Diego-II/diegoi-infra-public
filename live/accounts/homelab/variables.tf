variable "github_owner" {
  description = "GitHub owner for the homelab account's (future) OIDC deploy role."
  type        = string
  default     = "Diego-II"
}

variable "github_repo" {
  description = "Placeholder repo for the homelab OIDC deploy role; unused until a homelab repo exists."
  type        = string
  default     = "homelab"
}
