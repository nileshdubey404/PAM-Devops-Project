# ============================================================
# JENKINS EC2 INSTANCE
# ============================================================

resource "aws_instance" "terraform_ec2_jenkins" {

  ami           = var.jenkins_ami_id
  instance_type = var.jenkins_instance_type
  key_name      = var.jenkins_key_name

  subnet_id = var.public_subnet_id

  vpc_security_group_ids = [
    var.jenkins_security_group_id
  ]

  iam_instance_profile = var.jenkins_instance_profile_name

  associate_public_ip_address = true

  user_data = file("${path.module}/ec2-jenkins-user-data-LAPTOP-RR2OIRHC.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "${var.project_name}-jenkins"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}