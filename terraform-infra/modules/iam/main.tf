locals {
  metadata = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# JENKINS IAM ROLE
# ============================================================

resource "aws_iam_role" "terraform_jenkins_role" {
  name = "${var.project_name}-jenkins-role"

  # Trust Policy
  # Allows the Jenkins EC2 instance to assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.metadata, { Name = "${var.project_name}-jenkins-role" })

}


# ============================================================
# JENKINS INSTANCE PROFILE
# ============================================================

resource "aws_iam_instance_profile" "terraform_jenkins_profile" {
  name = "${var.project_name}-jenkins-instance-profile"
  role = aws_iam_role.terraform_jenkins_role.name

  tags = merge(local.metadata, { Name = "${var.project_name}-jenkins-instance-profile" })

}

# ============================================================
# AWS LOAD BALANCER CONTROLLER IAM ROLE
# ============================================================

resource "aws_iam_role" "terraform_aws_load_balancer_controller_role" {
  name = "${var.project_name}-aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowEksPodIdentity"
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = merge(local.metadata, { Name = "${var.project_name}-aws-load-balancer-controller-role" })
}

# ============================================================
# ATTACH LOAD BALANCER CONTROLLER POLICY
# ============================================================

resource "aws_iam_role_policy_attachment" "terraform_aws_load_balancer_controller_attachment" {
  role       = aws_iam_role.terraform_aws_load_balancer_controller_role.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}
