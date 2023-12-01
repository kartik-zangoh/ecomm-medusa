provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.my_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.my_cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.my_cluster.id]
      command     = "aws"
    }
  }
}


provider "kubernetes" {
  # config_path = var.config_path
    kubernetes {
    host                   = aws_eks_cluster.my_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.my_cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.my_cluster.id]
      command     = "aws"
    }
  }
}

output "cluster_endpoint" {
  description = "The EKS cluster endpoint"
  value       = aws_eks_cluster.my_cluster.endpoint
}

output "config_map_aws_auth" {
  value = data.aws_eks_cluster_auth.eks
}


# Create an IAM role for the EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-${var.eks_cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "amazon-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}


resource "aws_eks_cluster" "my_cluster" {
  name     = var.eks_cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {

    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]

    subnet_ids = [
      var.private_subnet-a.id,
      var.private_subnet-b.id,
      var.public_subnet-a.id,
      var.public_subnet-b.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.amazon-eks-cluster-policy]
}

# resource "aws_iam_role" "node_role" {
#   name = "eks-node-group-role"

#   assume_role_policy = jsonencode({
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#     }]
#     Version = "2012-10-17"
#   })
# }
# resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.node_role.name
# }
# resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.node_role.name
# }
# resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.node_role.name
# }
# resource "aws_eks_node_group" "node_group" {
#   cluster_name    = aws_eks_cluster.my_cluster.name
#   node_group_name = "cms_cluster_node_group"
#   node_role_arn   = aws_iam_role.node_role.arn

#   subnet_ids = [
#       var.private_subnet-a.id,
#       var.private_subnet-b.id,
#       var.public_subnet-a.id,
#       var.public_subnet-b.id
#     ]

#   ami_type = "AL2_ARM_64"
#   instance_types = ["m6g.medium"]
#   scaling_config {
#     desired_size = 1
#     max_size     = 2
#     min_size     = 1
#   }

#   update_config {
#     max_unavailable = 1
#   }

#   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
#   # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
#   depends_on = [
#     aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
#   ]
# }

resource "null_resource" "eks_update_kubeconfig" {
  depends_on = [aws_eks_cluster.my_cluster]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.eks_cluster_name} --region ap-south-1 "
  }
}

resource "aws_iam_role" "eks-fargate-profile" {
  name = "eks-fargate-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-fargate-profile" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks-fargate-profile.name
}

resource "aws_eks_fargate_profile" "kube-system" {
  cluster_name           = aws_eks_cluster.my_cluster.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn

  subnet_ids = [
      var.private_subnet-a.id,
      var.private_subnet-b.id,
    ]

  selector {
    namespace = "ecomm-kube-system"
  }

  tags = {
    "eks.amazonaws.com/cpu" = "1"
    "eks.amazonaws.com/memory" = "512"
    "eks.amazonaws.com/storage" = "20Gi"  # Specify storage size (e.g., 20Gi)
    # "eks.amazonaws.com/" = "arm64"    # Specify architecture (e.g., arm64)
    "eks.amazonaws.com/execution-duration" = "900" # Specify execution duration in seconds (e.g., 3600 for 1 hour)
  }
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.my_cluster.id
}


resource "null_resource" "update_fargate_annotation" {
  depends_on = [aws_eks_fargate_profile.kube-system]

  provisioner "local-exec" {
    command = <<-EOH
      kubectl patch deployment coredns -n kube-system --type json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
    EOH
  }
}

resource "helm_release" "postgres" {
  name = "newzera-cms-crawler"
  repository = "${path.module}/../../helm-charts"
  chart = "postgresql"
  namespace = "ecomm-kube-system"

  values = [file("${path.module}/../../helm-charts/postgresql/values.yaml")]

  depends_on = [aws_eks_fargate_profile.kube-system]
}

resource "helm_release" "backend" {
  name = "newzera-cms-crawler"
  repository = "${path.module}/../../helm-charts"
  chart = "dev-spc-backend"
  namespace = "ecomm-kube-system"

  values = [file("${path.module}/../../helm-charts/dev-spc-backend/values.yaml")]

  depends_on = [helm_release.postgres]
}

resource "helm_release" "reddis" {
  name = "newzera-cms-crawler"
  repository = "${path.module}/../../helm-charts"
  chart = "reddis"
  namespace = "ecomm-kube-system"

  values = [file("${path.module}/../../helm-charts/reddis/values.yaml")]

  depends_on = [helm_release.postgres]
}
