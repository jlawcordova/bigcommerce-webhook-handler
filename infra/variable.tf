variable "project" {
  description = "The name of the project. This is used for resource naming and tagging."
  type        = string
  default     = ""
  nullable    = true
}

variable "environment" {
  description = "The type of environment where the webhook handler is deployed. This is used for resource tagging."
  type        = string
  default     = "development"
}
