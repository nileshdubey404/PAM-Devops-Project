locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# Jenkins Security Group with inline ingress/egress blocks
# ============================================================

resource "aws_security_group" "terraform_jenkins_sg" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Security group for Jenkins EC2"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.project_name}-jenkins-sg" })
}

# Jenkins Web UI
resource "aws_vpc_security_group_ingress_rule" "jenkins_http" {
  security_group_id = aws_security_group.terraform_jenkins_sg.id

  cidr_ipv4   = var.admin_cidr
  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
  description = "Jenkins web interface"
}

# SSH access
resource "aws_vpc_security_group_ingress_rule" "jenkins_ssh" {
  security_group_id = aws_security_group.terraform_jenkins_sg.id

  cidr_ipv4   = var.admin_cidr
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  description = "SSH administration"
}

# Jenkins outbound traffic
resource "aws_vpc_security_group_egress_rule" "jenkins_all_outbound" {
  security_group_id = aws_security_group.terraform_jenkins_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
  description = "Allow outbound traffic"
}
