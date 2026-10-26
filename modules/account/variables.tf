variable "name" {
  description = "Account name as shown in Organizations."
  type        = string
}

variable "email" {
  description = "Unique root email. Use a Gmail plus-alias, e.g. owner+project-a@example.com"
  type        = string
}

variable "parent_id" {
  description = "OU id the account is placed under."
  type        = string
}

variable "tags" {
  description = "Tags applied to the account."
  type        = map(string)
  default     = {}
}
