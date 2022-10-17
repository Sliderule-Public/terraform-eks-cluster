resource "aws_eks_cluster" "main" {
  name     = "${var.environment}-eks"
  version  = ""
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids = local.eks_cluster_subnets_ids
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role.eks,
  ]
}

data "tls_certificate" "main" {
  url = local.eks_oidc_issuer
}
resource "aws_iam_openid_connect_provider" "main" {
  url = local.eks_oidc_issuer

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    data.tls_certificate.main.certificates.0.sha1_fingerprint
  ]
}
