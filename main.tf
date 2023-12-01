provider "aws" {
  region = var.aws_region  # Change to your desired AWS region
}



locals {
  # Database
  allocated_storage     = 10
  max_allocated_storage = 15
  db_identifier         = "prod-cms-2023"
  primary_db_name       = "cms_db"
}


module "vpc" {
  source     = "./modules/vpc"
  eks_cluster_name   = var.eks_cluster_name
}


# module "rds" {
#   source                = "./modules/rds"
#   allocated_storage     = local.allocated_storage
#   max_allocated_storage = local.max_allocated_storage
#   db_identifier         = local.db_identifier
#   db_name               = local.primary_db_name
#   master_user           = var.db_user
#   master_password       = var.db_password
#   security_group_ids    = [module.vpc.security_group.id]
#   subnet_ids            = [
#                             module.vpc.private_subnet-a.id,
#                             module.vpc.private_subnet-b.id,
#                           ]
# }

module "eks-cluster" {
  source             = "./modules/eks"
  eks_cluster_name   = var.eks_cluster_name
  cluster_version    = var.cluster_version
  namespace          = var.namespace
  config_path        = "${path.module}/output/kubeconfig.yaml"
  # helm_chart_path    = [file("${path.module}/values.yaml")]
  private_subnet-a   = module.vpc.private_subnet-a
  private_subnet-b   = module.vpc.private_subnet-b
  public_subnet-a    = module.vpc.public_subnet-a
  public_subnet-b    = module.vpc.public_subnet-a
  # rds_instance       = module.rds.rds_instance
  # rds_endpoint       = module.rds.database-endpoint
  # rds_user           = var.db_user
  # rds_password       = var.db_password
  # rds_db             = local.primary_db_name
}