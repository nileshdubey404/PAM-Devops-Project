# ============================================================
# JENKINS SECURITY GROUP
# ============================================================

output "jenkins_security_group_id" {
  description = "ID of the Jenkins security group"
  value       = aws_security_group.terraform_jenkins_sg.id
}

