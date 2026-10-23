# ============================================================
# JENKINS MODULE VARIABLES
# ============================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "jenkins_ami_id" {
  description = "AMI ID for Jenkins EC2"
  type        = string
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID where Jenkins will be deployed"
  type        = string
}

variable "jenkins_security_group_id" {
  description = "Security group ID for Jenkins"
  type        = string
}

variable "jenkins_instance_profile_name" {
  description = "IAM instance profile attached to Jenkins EC2"
  type        = string
}

variable "jenkins_key_name" {
  description = "Existing EC2 key pair name for Jenkins"
  type        = string
}