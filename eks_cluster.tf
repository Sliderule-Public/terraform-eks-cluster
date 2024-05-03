data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

locals {
  subnet_tag_selectors = {
    for selector in var.karpenter_subnet_selector_tags : selector.key => selector.value
  }
  karpenter_roles = [
    {
      rolearn  = module.karpenter.node_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:masters"]
    }
  ]
  aws_auth_users = [
    for arn in var.kubernetes_master_user_arns :
    {
      userarn  = arn
      username = split("/", arn)[length(split("/", arn)) - 1]
      groups   = ["system:masters"]
    }
  ]

  base_auth_configmap         = yamldecode(module.eks.aws_auth_configmap_yaml)
  updated_auth_configmap_data = {
    data = {
      mapRoles = yamlencode(
        distinct(concat(
          yamldecode(local.base_auth_configmap.data.mapRoles), local.karpenter_roles)
        ))
      mapUsers = yamlencode(local.aws_auth_users)
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name                    = var.name
  cluster_version                 = var.eks_cluster_version
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true
  control_plane_subnet_ids        = var.public_eks_api_access ? var.public_subnet_ids : var.private_subnet_ids

  enable_irsa = true

  kms_key_administrators = ["arn:aws:iam::${local.account_id}:root"]
  kms_key_users          = ["arn:aws:iam::${local.account_id}:root"]

  cluster_addons = {
    coredns = {
      configuration_values = jsonencode({
        computeType = "Fargate"
        resources   = {
          limits = {
            cpu    = "0.25"
            memory = "256M"
          }
          requests = {
            cpu    = "0.25"
            memory = "256M"
          }
        }
      })
    }
    kube-proxy         = {}
    aws-ebs-csi-driver = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
    vpc-cni = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }

  fargate_profiles = {
    karpenter = {
      selectors = [
        { namespace = "karpenter" }
      ]
    }
    kube-system = {
      selectors = [
        { namespace = "kube-system" }
      ]
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  node_security_group_additional_rules = merge(var.node_security_group_additional_rules, var.node_security_group_sg_ingress_additional_rules)

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.name
  }

  cluster_security_group_additional_rules = {
    https_access = {
      description = "HTTPS access"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    "karpenter.sh/discovery" = var.name
  }

  create_cluster_security_group = true
  create_node_security_group    = false

  # Bug in the module, see below
  manage_aws_auth_configmap = false
}

resource "time_sleep" "wait_for_cluster" {
  depends_on = [module.eks]

  create_duration = "60s"
}

resource "null_resource" "wait_for_cluster" {
  depends_on = [time_sleep.wait_for_cluster]
}


module "karpenter" {
  depends_on = [
    null_resource.wait_for_cluster
  ]
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = var.name

  tags = {
    "karpenter.sh/discovery" = var.name
  }

  enable_irsa                       = true
  irsa_oidc_provider_arn            = module.eks.oidc_provider_arn
  create_access_entry               = false
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "helm_release" "karpenter" {
  depends_on = [
    null_resource.wait_for_cluster
  ]
  namespace           = "karpenter"
  create_namespace    = true
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "0.35.1"
  wait                = true

  values = [
    <<-EOT
    additionalAnnotations:
      'eks.amazonaws.com/compute-type': Fargate
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
      featureGates:
        spotToSpotConsolidation: true
    serviceAccount:
      annotations:
        'eks.amazonaws.com/role-arn': '${module.karpenter.iam_role_arn}'
    tolerations:
      - key: 'eks.amazonaws.com/compute-type'
        operator: Equal
        value: fargate
        effect: "NoSchedule"
    EOT
  ]
}

resource "time_sleep" "wait_for_karpenter" {
  depends_on = [helm_release.karpenter]

  create_duration = "90s"
}

resource "null_resource" "wait_for_karpenter" {
  depends_on = [time_sleep.wait_for_karpenter]
}


resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      role: ${module.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            ${jsonencode(local.subnet_tag_selectors)}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter,
    null_resource.wait_for_cluster
  ]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["c", "m", "r"]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ["2", "4", "8", "16", "32"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64"]
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["spot", "on-demand"]
      limits:
        cpu: 1000
      disruption:
        consolidationPolicy: WhenUnderutilized
        expireAfter: 72h
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class,
    null_resource.wait_for_cluster
  ]
}

data "aws_iam_roles" "sso_role" {
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "kubernetes_config_map" "aws_auth" {
  depends_on = [
    module.eks,
    null_resource.wait_for_cluster
  ]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}

data "aws_iam_users" "users" {}

# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1280#issuecomment-810533105
resource "kubernetes_config_map_v1_data" "aws_auth" {
  force = true

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.updated_auth_configmap_data.data

  depends_on = [
    module.eks,
  ]
}