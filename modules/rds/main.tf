variable "subnet_ids" {
  type        = list(string)
  description = "List of Subnet IDs to put in the RDS DB subnet group. Minimum 2 are required"
}

variable "allocated_storage" {
  type        = number
  description = "Minimum allocated storage for the DB instance"
}

variable "max_allocated_storage" {
  type        = number
  description = "Maximum allocated storage for the DB instance"
}

variable "engine" {
  type        = string
  description = "Database Engine to be used. Defaults to mariadb"
  default     = "mysql"
}

variable "engine_version" {
  type        = string
  description = "Version of the Database Engine specified in the `engine` parameter to be used. Defaults to 10.5.12"
  default     = "8.0.35"
}

variable "instance_class" {
  type        = string
  description = "Instance type to be used for the RDS instance"
  default     = "db.t4g.medium"
}

variable "db_identifier" {
  type        = string
  description = "Unique identifier for the RDS instance. This will also be used as a prefix for naming some miscellaneous elements created along with RDS"
}

variable "db_name" {
  type        = string
  description = "Name of the database created while creating the RDS instance"
}

variable "master_user" {
  type        = string
  description = "Master username for logging in to the database"
}

variable "master_password" {
  type        = string
  description = "Master password for logging in to the database"
  sensitive   = true
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of Security Group IDs to be attached to the RDS instance"
  sensitive   = true
}

output "rds_instance" {
  value       = aws_db_instance.rds
  description = "The created RDS instance object"
}

output "database-endpoint" {
  value = aws_db_instance.rds.address
}

resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "${var.db_identifier}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.db_identifier}-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "db-parameter-group" {
  name   = "${var.db_identifier}-db-parameter-group"
  family = "mysql8.0"

  parameter {
    name  = "wait_timeout"
    value = "300"
  }

  parameter {
    name  = "max_connections"
    value = "500"
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage         = var.allocated_storage
  max_allocated_storage     = var.max_allocated_storage
  engine                    = var.engine
  engine_version            = var.engine_version
  instance_class            = var.instance_class
  identifier                = var.db_identifier
  db_name                   = var.db_name
  username                  = var.master_user
  password                  = var.master_password
  port                      = 3306
  storage_type              = "gp2"
  db_subnet_group_name      = aws_db_subnet_group.rds-subnet-group.name
  final_snapshot_identifier = "${var.db_identifier}-snapshot"
  vpc_security_group_ids    = var.security_group_ids
  parameter_group_name      = aws_db_parameter_group.db-parameter-group.name
  deletion_protection       = false

  # provisioner "local-exec" {
  #   command = "mysql -h ${self.endpoint} -u ${var.master_user} -p${var.master_password} ${var.db_name} < ${path.module}/../../mysql/table_schema.sql"
  # }

  depends_on = [aws_db_parameter_group.db-parameter-group]
}





# resource "null_resource" "run_sql_script" {
#   provisioner "remote-exec" {
#     inline = [
#       "mysql -h prod-cms-2023.cvvnktdvsk7v.ap-south-1.rds.amazonaws.com -u admin -p${aws_db_instance.rds.password} < ${path.module}/../../mysql/table_schema.sql",
#     ]
#   }

#   depends_on = [aws_db_instance.rds]
# }

