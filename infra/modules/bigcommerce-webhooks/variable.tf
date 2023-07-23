variable "project" {
  description = "The name of the project. This is used for resource naming and tagging."
  type        = string
  default     = "bigcommerce-webhook"
}

variable "lambda_src_path" {
  type        = string
  default     = "/../../../src/dist"
  description = "The relative path of where the source code for the lambda function resides."
}

variable "environment" {
  type        = string
  default     = "development"
  description = "The type of environment where the webhook handler is deployed. This is used for resource tagging."
}
