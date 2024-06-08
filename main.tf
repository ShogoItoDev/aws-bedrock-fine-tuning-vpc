provider "aws" {
  region = "us-east-1"
}

variable "system_identifier" {
  description = "Identifier for the system"
  default     = "demo"
  type        = string
}

variable "s3_managed_prefix_id" {
  type    = string
  default = "pl-63a5400a" # S3 managed prefix id in us-east-1.
}