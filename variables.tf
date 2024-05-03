variable "name" {
  type        = string
  description = "used in resource naming"
}
variable "region" {
  type        = string
  description = "aws region to deploy into"
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
variable "eks_cluster_version" {
  type        = string
  default     = "1.29"
  description = "EKS cluster version"
}
variable "public_eks_api_access" {
  type        = bool
  default     = false
  description = "If true, will allow public access to the EKS API server"
}
variable "node_security_group_additional_rules" {
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default     = {}
  description = "Additional cidr rules to add to the node security group"
}
variable "node_security_group_sg_ingress_additional_rules" {
  type = map(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    source_security_group_id = string
  }))
  default     = {}
  description = "Additional sg ingress rules to add to the node security group"
}

variable "karpenter_subnet_selector_tags" {
  type = list(object({
    key   = string
    value = string
  }))
  description = "Karpenter node selector"
}
variable "kubernetes_master_user_arns" {
  type        = list(string)
  description = "IAM users that can access the EKS cluster"
  default     = []
}