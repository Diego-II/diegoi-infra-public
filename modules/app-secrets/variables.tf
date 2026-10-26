variable "app_name" {
  description = "App short name; secrets are namespaced as /<app_name>/<KEY>."
  type        = string
}

variable "keys" {
  description = "Secret keys to create as SecureString params. Values are set out-of-band, never here."
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
