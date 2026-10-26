variable "admin_email" {
  description = "Email for your Identity Center (SSO) user."
  type        = string
  default     = "owner@example.com"
}

variable "admin_given_name" {
  type    = string
  default = "Diego"
}

variable "admin_family_name" {
  type    = string
  default = "Doe"
}
