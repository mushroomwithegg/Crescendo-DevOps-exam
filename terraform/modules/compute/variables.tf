variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "crescendo"
}

variable "vpc_id" {
  description = "VPC id where instance will be launched"
  type        = string
}

variable "public_subnet_id" {
  description = "A public subnet id to launch the instance in"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN to register the instance with"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group id (used as source for instance SG rules)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 50
}

variable "volume_type" {
  description = "EBS volume type"
  type        = string
  default     = "gp2"
}
