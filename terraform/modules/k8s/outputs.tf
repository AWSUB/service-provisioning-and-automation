output "master_public_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "worker_public_ip" {
  value = aws_instance.k8s_worker.public_ip
}

output "ssh_master" {
  value = "ssh -i ~/.ssh/id_ed25519 ec2-user@${aws_instance.k8s_master.public_ip}"
}

output "ssh_worker" {
  value = "ssh -i ~/.ssh/id_ed25519 ec2-user@${aws_instance.k8s_worker.public_ip}"
}