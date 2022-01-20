variable "environment" {
  type        = string
  description = "Environment"
}

variable "cidr_block" {
  type        = string
  description = "VPC's CIDR block"
  default     = "10.0.0.0/16"
}

variable "subnet_new_bits" {
  type        = number
  description = "Number of subnets new bits."
  default     = 8
}

variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets. If zero is provided, then it will take the number of available AZs in the region."
  default     = -1
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnet"
  default     = -1
}

variable "region" {
  type        = string
  description = "Region for deployment"
}