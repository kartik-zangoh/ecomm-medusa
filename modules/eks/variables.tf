variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
  default     = "ecomm_cluster"
}

variable "namespace" {
  description = "The name of the kubernetes namespace."
  type        = string
  default     = "xyz"
}

variable "cluster_version" {
  default = "1.28"
}

variable "config_path" {
  description = "The path of eks config file"
  type        = string
}

# variable "helm_chart_path" {
#   description = "The path of helm chart files"
#   type        = list
# }

variable "private_subnet-a" {
  description = "The name of the private subnet a object."
}
variable "private_subnet-b" {
  description = "The name of the private subnet b object."
}
variable "public_subnet-a" {
  description = "The name of the public subnet a object."
}
variable "public_subnet-b" {
  description = "The name of the public subnet b object."
}

variable "rds_instance" {
  description = "The rds instance of mysql"
}

variable "rds_endpoint" {
  description = "The endpoint of rds instance"
}

variable "rds_user" {
  description = "The user of rds instance"
  default = "admin"
}

variable "rds_db" {
  description = "The db name of rds instance"
  default = "cms_db"
}

variable "rds_port" {
  description = "The port of rds instance"
  default = 3306
}

variable "rds_password" {
  description = "The endpoint of rds instance"
  default = "newzera1"
}