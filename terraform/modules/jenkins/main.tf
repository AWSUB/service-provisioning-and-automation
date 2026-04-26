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
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "jenkins_key_pair" {
  key_name   = "jenkins-key-pair"
  public_key = file(var.public_key_path)
}

resource "tls_private_key" "jenkins_to_k8s_key" {
  algorithm = "ED25519"

}

resource "aws_security_group" "jenkins_security_group" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins instance"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Jenkins
  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "jenkins-sg"
  }
}

resource "aws_instance" "jenkins_instance" {
  ami                    = var.instance_image
  instance_type          = var.instance_type
  key_name               = aws_key_pair.jenkins_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_security_group.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "${tls_private_key.jenkins_to_k8s_key.public_key_openssh}" > /home/ec2-user/.ssh/id_ed25519.pub
              echo "${tls_private_key.jenkins_to_k8s_key.private_key_openssh}" > /home/ec2-user/.ssh/id_ed25519
              chown ec2-user:ec2-user /home/ec2-user/.ssh/id_ed25519.pub
              chown ec2-user:ec2-user /home/ec2-user/.ssh/id_ed25519
              chmod 600 /home/ec2-user/.ssh/id_ed25519
              EOF

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "jenkins-instance"
  }
}

# Docs: https://registry.terraform.io/providers/ansible/ansible/latest/docs/resources/playbook

data "ansible_inventory" "jenkins_inventory" {
  group {
    name = "jenkins"

    host {
      name                     = aws_instance.jenkins_instance.public_ip
      ansible_user             = "ec2-user"
      ansible_private_key_file = var.private_key_path
      ansible_ssh_common_args  = "-o StrictHostKeyChecking=no"
    }
  }
}

resource "null_resource" "jenkins_setup" {
  lifecycle {
    action_trigger {
      events  = [after_create, after_update]
      actions = [action.ansible_playbook_run.jenkins_setup_action]
    }
  }

  depends_on = [aws_instance.jenkins_instance]
}

action "ansible_playbook_run" "jenkins_setup_action" {
  config {
    playbooks   = ["${path.module}/ansible/site.yml"]
    inventories = [data.ansible_inventory.jenkins_inventory.json]
    verbosity   = 1
  }
}
