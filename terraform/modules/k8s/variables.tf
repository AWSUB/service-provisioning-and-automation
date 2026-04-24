variable "aws_region" {
  description = "AWS region for resources"
  default     = "ap-southeast-2"
}

variable "instance_type_master" {
  description = "Instance type for EC2 master node"
  default     = "t3.small"
}

variable "instance_type_worker" {
  description = "Instance type for EC2 worker node"
  default     = "t3.small"
}

variable "instance_image" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-0960d4ee09fcfb466"
}

variable "public_key_path" {
  description = "Public key path for SSH"
  default     = "~/.ssh/id_ed25519.pub"
}

variable "private_key_path" {
  description = "Private key path for SSH"
  default     = "~/.ssh/id_ed25519"
}

variable "my_ip" {
  description = "Your IP address for security group rules"
  default     = "0.0.0.0/0"
}
