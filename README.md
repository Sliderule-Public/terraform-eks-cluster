# EKS Terraform Module

## Details
This module creates an EKS cluster to host the Sliderule app in AWS EKS. The cluster's nodes are powered by Karpenter.

## Prerequisites
- Subnets need the tag `karpenter.sh/discovery = var.name` to be used by the karpenter operator.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | 2.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.75.2 |
| <a name="provider_aws.virginia"></a> [aws.virginia](#provider\_aws.virginia) | 3.75.2 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 2.0.4 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.1 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ebs_csi_irsa"></a> [ebs\_csi\_irsa](#module\_ebs\_csi\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 19.16.0 |
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | terraform-aws-modules/eks/aws//modules/karpenter | n/a |
| <a name="module_vpc_cni_irsa"></a> [vpc\_cni\_irsa](#module\_vpc\_cni\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.eks_alb_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [helm_release.alb_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.karpenter_node_class](https://registry.terraform.io/providers/alekc/kubectl/2.0.4/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_node_pool](https://registry.terraform.io/providers/alekc/kubectl/2.0.4/docs/resources/manifest) | resource |
| [kubernetes_config_map_v1_data.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) | resource |
| [kubernetes_namespace.alb_controller](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_service_account.alb_controller](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [null_resource.wait_for_alb_controller](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_for_cluster](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_for_karpenter](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [time_sleep.wait_for_alb_controller](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_cluster](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_karpenter](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecrpublic_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecrpublic_authorization_token) | data source |
| [aws_eks_cluster_auth.app_eks_cluster_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_roles.sso_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_roles) | data source |
| [aws_iam_users.users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_users) | data source |
| [kubernetes_config_map.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/config_map) | data source |
| [tls_certificate.main](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks_cluster_version"></a> [eks\_cluster\_version](#input\_eks\_cluster\_version) | EKS cluster version | `string` | `"1.29"` | no |
| <a name="input_karpenter_subnet_selector_tags"></a> [karpenter\_subnet\_selector\_tags](#input\_karpenter\_subnet\_selector\_tags) | Karpenter node selector | <pre>list(object({<br>    key   = string<br>    value = string<br>  }))</pre> | n/a | yes |
| <a name="input_kubernetes_master_user_arns"></a> [kubernetes\_master\_user\_arns](#input\_kubernetes\_master\_user\_arns) | IAM users that can access the EKS cluster | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | used in resource naming | `string` | n/a | yes |
| <a name="input_node_security_group_additional_rules"></a> [node\_security\_group\_additional\_rules](#input\_node\_security\_group\_additional\_rules) | Additional cidr rules to add to the node security group | <pre>map(object({<br>    from_port   = number<br>    to_port     = number<br>    protocol    = string<br>    cidr_blocks = list(string)<br>  }))</pre> | `{}` | no |
| <a name="input_node_security_group_sg_ingress_additional_rules"></a> [node\_security\_group\_sg\_ingress\_additional\_rules](#input\_node\_security\_group\_sg\_ingress\_additional\_rules) | Additional sg ingress rules to add to the node security group | <pre>map(object({<br>    from_port                = number<br>    to_port                  = number<br>    protocol                 = string<br>    source_security_group_id = string<br>  }))</pre> | `{}` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | only needed if create\_vpc is false. Private subnets to use to host some private resources in this stack | `list(string)` | `[]` | no |
| <a name="input_public_eks_api_access"></a> [public\_eks\_api\_access](#input\_public\_eks\_api\_access) | If true, will allow public access to the EKS API server | `bool` | `false` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | only needed if create\_vpc is false. Public subnets to use to host some public resources in this stack | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | aws region to deploy into | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | only needed if create\_vpc is false. VPC to use to host resources in this stack | `string` | `""` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->