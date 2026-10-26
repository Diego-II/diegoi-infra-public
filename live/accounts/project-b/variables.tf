variable "github_owner" {
  description = "Your personal GitHub owner."
  type        = string
  default     = "Diego-II"
}

variable "github_repo" {
  description = "Scopes the OIDC deploy role's trust. The project does NOT use GitHub Actions for infra -- applies are run locally -- so this role is currently unused. Left in place in case app (not infra) CI is added later."
  type        = string
  default     = "project-b"
}

variable "subdomain" {
  description = "Subdomain delegated into this account. Trailing dot omitted; Route53 normalises."
  type        = string
  default     = "project-b.example.net"
}

variable "parent_zone_id" {
  description = "Hosted zone for example.net in the MANAGEMENT account. The registrar delegates to it, so NS records added here resolve publicly."
  type        = string
  default     = "Z0000000EXAMPLEZONE00"
}
