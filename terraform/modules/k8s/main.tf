# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "~> 1.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "k8s_key_pair" {
  key_name   = "k8s-key-pair"
  public_key = file(var.public_key_path)
}

resource "aws_vpc" "k8s_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "k8s-vpc"
  }
}

resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "k8s-igw"
  }
}

resource "aws_subnet" "k8s_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-subnet"
  }
}

resource "aws_route_table" "k8s_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }

  tags = {
    Name = "k8s-rt"
  }
}

resource "aws_route_table_association" "k8s_rta" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_rt.id
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Security group for Kubernetes cluster"
  vpc_id      = aws_vpc.k8s_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Kubernetes API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Internal traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # NodePort range for Kubernetes services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-sg"
  }
}

resource "aws_instance" "k8s_master" {
  ami                    = var.instance_image
  instance_type          = var.instance_type_master
  subnet_id              = aws_subnet.k8s_subnet.id
  key_name               = aws_key_pair.k8s_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-master"
    Role = "master"
  }
}

resource "aws_instance" "k8s_worker" {
  ami                    = var.instance_image
  instance_type          = var.instance_type_worker
  subnet_id              = aws_subnet.k8s_subnet.id
  key_name               = aws_key_pair.k8s_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-worker"
    Role = "worker"
  }
}

# Docs: https://registry.terraform.io/providers/ansible/ansible/latest/docs/resources/playbook

data "ansible_inventory" "k8s_inventory" {
  group {
    name = "master"

    host {
      name                     = aws_instance.k8s_master.public_ip
      ansible_user             = "ec2-user"
      ansible_private_key_file = var.private_key_path
      ansible_ssh_common_args  = "-o StrictHostKeyChecking=no"
    }
  }
  group {
    name = "worker"

    host {
      name                     = aws_instance.k8s_worker.public_ip
      ansible_user             = "ec2-user"
      ansible_private_key_file = var.private_key_path
      ansible_ssh_common_args  = "-o StrictHostKeyChecking=no"
    }
  }
}

resource "null_resource" "k8s_setup" {
  lifecycle {
    action_trigger {
      events  = [after_create, after_update]
      actions = [action.ansible_playbook_run.k8s_setup_action]
    }
  }

  depends_on = [data.ansible_inventory.k8s_inventory]
}

action "ansible_playbook_run" "k8s_setup_action" {
  config {
    playbooks   = ["${path.module}/ansible/site.yml"]
    inventories = [data.ansible_inventory.k8s_inventory.json]
    verbosity = 1
  }
}
