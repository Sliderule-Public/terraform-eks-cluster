variable "company_name" {
  type        = string
  description = "used in resource naming"
}
variable "environment" {
  type        = string
  description = "used in resource naming and namespacing"
}
variable "region" {
  type        = string
  description = "aws region to deploy into"
}
variable "tags" {
  type        = any
  default     = {}
  description = "optional AWS tags to apply to most resources deployed with this stack"
}
variable "vpc_id" {
  type        = string
  description = "only needed if create_vpc is false. VPC to use to host resources in this stack"
  default     = ""
}
variable "private_subnet_ids" {
  type        = list(string)
  description = "only needed if create_vpc is false. Private subnets to use to host some private resources in this stack"
  default     = []
}
variable "public_subnet_ids" {
  type        = list(string)
  description = "only needed if create_vpc is false. Public subnets to use to host some public resources in this stack"
  default     = []
}
variable "app_name" {
  type        = string
  default     = "shieldrule"
  description = "used to build an SSH key name for the optional EKS node group."
}
variable "use_only_private_subnets" {
  type    = bool
  default = false
  description = "If true, will use only private subnets to provision all network-dependant resources"
}
