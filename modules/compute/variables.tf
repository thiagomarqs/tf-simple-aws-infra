variable "region" {
  description = "Region where all resources will be created in."
  type        = string
}

variable "subnet_id" {
  description = "The id of the subnet where the EC2 instance must be deploy."
  type = string
}

variable "vpc_security_group_ids" {
  description = "The list of the ids of the security groups to be associated with the EC2 instance that will be deployed."
  type = list(string)
}