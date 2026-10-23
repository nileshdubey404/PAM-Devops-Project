# ============================================================
# JENKINS OUTPUTS
# ============================================================

output "jenkins_instance_id" {
  description = "Jenkins EC2 instance ID"
  value       = aws_instance.terraform_ec2_jenkins.id
}

output "jenkins_private_ip" {
  description = "Private IP address of Jenkins EC2"
  value       = aws_instance.terraform_ec2_jenkins.private_ip
}

output "jenkins_public_ip" {
  description = "Public IP address of Jenkins EC2"
  value       = aws_instance.terraform_ec2_jenkins.public_ip
}