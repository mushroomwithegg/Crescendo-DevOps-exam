variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "crescendo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# By default use first two availability zones
variable "az_count" {
  description = "Number of AZs to create subnets in"
  type        = number
  default     = 2
}
