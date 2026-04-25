output "jenkins_public_ip" {
  value = aws_instance.jenkins_instance.public_ip
}

output "ssh_jenkins" {
  value = "ssh -i ~/.ssh/id_ed25519 ec2-user@${aws_instance.jenkins_instance.public_ip}"
}
