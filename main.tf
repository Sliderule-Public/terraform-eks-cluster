data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      "Terraform"  = "true"
      "Stack Name" = var.name
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}


locals {
  account_id          = data.aws_caller_identity.current.account_id
  eks_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  alb_controller_name = "alb-controller"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "2.0.4"
    }
  }
}

data "aws_eks_cluster_auth" "app_eks_cluster_auth" {
  name = module.eks.cluster_name
}

data "tls_certificate" "main" {
  url = module.eks.cluster_oidc_issuer_url
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.app_eks_cluster_auth.token
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.app_eks_cluster_auth.token
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.app_eks_cluster_auth.token
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
}