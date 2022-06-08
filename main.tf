provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = "rds-terra"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "rds-terra" {
  name       = "rds-terra"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "rds-terra"
  }
}

resource "aws_security_group" "rds" {
  name   = "rds-terra_rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-terra_rds"
  }
}

resource "aws_db_parameter_group" "rds-terra" {
  name   = "rds-terra"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "rds-terra" {
  identifier             = "rds-terra"
  instance_class         = "db.t3.small"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "14.2"
  username               = "rds_terra"
  password               = "terra123"
  db_subnet_group_name   = aws_db_subnet_group.rds-terra.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.rds-terra.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}