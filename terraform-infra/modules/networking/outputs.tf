# ============================================================
# VPC
# ============================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.terraform_vpc.id
}


# ============================================================
# PUBLIC SUBNETS
# ============================================================

output "public_subnet_ids" {
  description = "IDs of all public subnets"
  value       = aws_subnet.terraform_public_subnet[*].id
}


# ============================================================
# PRIVATE SUBNETS
# ============================================================

output "private_subnet_ids" {
  description = "IDs of all private subnets"
  value       = aws_subnet.terraform_private_subnet[*].id
}


# ============================================================
# NAT GATEWAY
# ============================================================

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.terraform_nat_gateway.id
}


# ============================================================
# INTERNET GATEWAY
# ============================================================

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.terraform_igw.id
}