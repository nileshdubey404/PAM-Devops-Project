terraform {
  backend "s3" {
    bucket = "aws-infra-remote-backend-tfstate-bucket-123456"
    key    = "s3-backend/terraform.tfstate"
    region = "ap-south-1"
  }
}