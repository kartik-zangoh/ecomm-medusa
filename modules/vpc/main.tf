variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
  default     = "ecomm_cluster"
}

output "vpc" {
  value       = aws_vpc.vpc
  description = "The created VPC object"
}

output "public_subnet-a" {
  value       = aws_subnet.public-ap-south-1a
  description = "The created Public subnet A object"
}

output "public_subnet-b" {
  value       = aws_subnet.public-ap-south-1b
  description = "The created Public subnet B object"
}

output "private_subnet-a" {
  value       = aws_subnet.private-ap-south-1a
  description = "The list of Private subnet objects"
}

output "private_subnet-b" {
  value       = aws_subnet.private-ap-south-1b
  description = "The list of Private subnet objects"
}

output "security_group" {
  value       = aws_security_group.open_sg
  description = "The created deafult Security Group object"
}

# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
   
  # Must be enabled for EFS
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ecomm-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "ecomm-vpc-igw"
  }
}

resource "aws_subnet" "private-ap-south-1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "ap-south-1a"

  tags = {
    "Name"                                      = "private-ap-south-1a"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}

resource "aws_subnet" "private-ap-south-1b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "ap-south-1b"

  tags = {
    "Name"                                      = "private-ap-south-1b"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}


resource "aws_subnet" "public-ap-south-1a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name"                                      = "public-ap-south-1a"
  }
}

resource "aws_subnet" "public-ap-south-1b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    "Name"                                      = "public-ap-south-1b"
  }
}

resource "aws_eip" "eip" {
  vpc = true

  tags = {
    Name = "ecomm-vpc-eip"
  }
}

resource "aws_nat_gateway" "nat" {

  connectivity_type = "public"
  
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public-ap-south-1a.id

  tags = {
    Name = "ecomm-vpc-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_security_group" "open_sg" {
  name        = "vpc-open-sg"
  description = "Open SG to allow all ingress and egress"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "vpc-open-sg"
  }
}

# resource "aws_security_group_rule" "allow_ingress" {
#   security_group_id = aws_security_group.open_sg.id
#   type              = "ingress"
#   from_port         = 3306  # MySQL port, adjust as needed
#   to_port           = 3306  # MySQL port, adjust as needed
#   protocol          = "tcp"

#   // Specify the IP address range you want to allow
#   cidr_blocks = ["13.127.64.19/32"]  # Replace with the actual IP address range

#   description = "Allow inbound traffic from specific IP address"
# }

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "private-ap-south-1a" {
  subnet_id      = aws_subnet.private-ap-south-1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-ap-south-1b" {
  subnet_id      = aws_subnet.private-ap-south-1b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public-ap-south-1a" {
  subnet_id      = aws_subnet.public-ap-south-1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-ap-south-1b" {
  subnet_id      = aws_subnet.public-ap-south-1b.id
  route_table_id = aws_route_table.public.id
}