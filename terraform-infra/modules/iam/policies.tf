# Jenkins needs to authenticate to ECR and push Docker images.

# ============================================================
# JENKINS → ECR
# ============================================================

resource "aws_iam_policy" "jenkins_ecr_policy" {
  name        = "${var.project_name}-jenkins-ecr-policy"
  description = "Allows Jenkins to push Docker images to Amazon ECR"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]

        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "jenkins_ecr_policy_attachment" {
  role       = aws_iam_role.terraform_jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_ecr_policy.arn
}

### Jenkins needs AWS permissions to obtain EKS cluster credentials.

# ============================================================
# JENKINS → EKS
# ============================================================

resource "aws_iam_policy" "jenkins_eks_policy" {
  name        = "${var.project_name}-jenkins-eks-policy"
  description = "Allows Jenkins to describe EKS clusters"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "jenkins_eks_policy_attachment" {
  role       = aws_iam_role.terraform_jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_eks_policy.arn
}

# ============================================================
# AWS LOAD BALANCER CONTROLLER IAM POLICY
# ============================================================

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.project_name}-aws-load-balancer-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = file("${path.module}/policies/aws_load_balancer_controller_policy.json")

  tags = {
    Name        = "${var.project_name}-aws-load-balancer-controller-policy"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
