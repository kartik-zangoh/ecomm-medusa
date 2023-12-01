output "cluster_endpoint" {
  description = "The EKS cluster endpoint"
  value       = module.eks-cluster.cluster_endpoint
}

output "private-subnet-a" {
  description = "The subnet id of private subnet A"
  value = module.vpc.private_subnet-a.id
}

output "private-subnet-b" {
  description = "The subnet id of private subnet B"
  value = module.vpc.private_subnet-b.id
}

output "vpc" {
  description = "The vpc object of prod_cms_2023"
  value = module.vpc.vpc
}

# output "kubeconfig" {
#   description = "Kubeconfig for accessing the cluster"
#   value       = data.external.generate_kubeconfig.result.kubeconfig
# }


# output "rds" {
#   value       = module.rds.rds_instance
#   description = "RDS instance object"
#   sensitive   = true
# }

# output "rds-endpoint" {
#   value       = module.rds.database-endpoint
# }