variable "project" {
  description = "Project name for naming resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, qa, prod)"
  type        = string
}

variable "s3_retention_days" {
  description = "Number of days to retain objects in S3 bucket before expiration"
  type        = number
}

variable "api_key" {
  description = "API Key value for the API Gateway Usage Plan"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
