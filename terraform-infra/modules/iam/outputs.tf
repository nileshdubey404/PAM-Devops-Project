
# ============================================================
# JENKINS ROLE
# ============================================================

output "jenkins_role_arn" {
  description = "ARN of the Jenkins IAM role"
  value       = aws_iam_role.terraform_jenkins_role.arn
}


# ============================================================
# JENKINS INSTANCE PROFILE
# ============================================================

output "jenkins_instance_profile_name" {
  description = "Name of the Jenkins EC2 instance profile"
  value       = aws_iam_instance_profile.terraform_jenkins_profile.name
}


# ============================================================
# AWS LOAD BALANCER CONTROLLER ROLE
# ============================================================

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the IAM role used by AWS Load Balancer Controller"

  value = aws_iam_role.terraform_aws_load_balancer_controller_role.arn
}
