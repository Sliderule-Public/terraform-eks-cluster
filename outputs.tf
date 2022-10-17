output "ENVIRONMENT" {
  value = var.environment
}

output "SENTRY_ENVIRONMENT" {
  value = var.environment
}

output "SHIELDRULE_ENVIRONMENT" {
  value = var.environment
}

output "EKS_ALB_CONTROLLER_ROLE_ARN" {
  value = aws_iam_role.eks-alb-controller.arn
}
