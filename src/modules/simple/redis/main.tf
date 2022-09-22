resource "aws_elasticache_subnet_group" "subnet_group" {
  name       = substr("${var.company_name}-${var.environment}-${var.name}", 0, 64)
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_cluster" "cluster" {
  cluster_id           = substr("${var.company_name}-${var.environment}-${var.name}", 0, 64)
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
  security_group_ids = var.security_group_ids
  subnet_group_name = aws_elasticache_subnet_group.subnet_group.name
}