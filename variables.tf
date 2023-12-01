# variable "cluster_name" {
#   description = "The name of the EKS cluster"
#   type        = string
# }

# Add more variables as needed

# variables.tf

variable "aws_region" {
  description = "The AWS region where the resources will be created."
  type        = string
  default     = "ap-south-1"
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
  default     = "ecomm_cluster"
}

variable "namespace" {
  description = "The name of the kubernetes namespace."
  type        = string
  default     = "ecomm_cluster_namespace"
}

variable "cluster_version" {
  default = "1.28"
}

variable "db_user" {
  type        = string
  description = "Username for the RDS DB instance"
  default     = "admin"
}

variable "db_password" {
  type        = string
  description = "Password for the RDS DB instance"
  sensitive   = true
  default     = "newzera1"
}
# Define other variables as needed
