data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}


locals {
  account_id              = data.aws_caller_identity.current.account_id
  vpc_id                  = var.vpc_id
  public_subnet_ids       = var.public_subnet_ids
  private_subnet_ids      = var.private_subnet_ids
  eks_oidc_issuer         = aws_eks_cluster.main.identity[0].oidc[0].issuer
  eks_cluster_subnets_ids = var.use_only_private_subnets == true ? local.private_subnet_ids : local.public_subnet_ids
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }

    grafana = {
      source  = "grafana/grafana"
      version = "~> 1.12.0"
    }

    auth0 = {
      source = "alexkappa/auth0"
    }
  }

  required_version = ">= 0.14.9"
}
