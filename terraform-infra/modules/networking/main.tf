locals {
  metadata = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

################################### VPC CREATION ##########################

## enable_dns_support and enable_dns_hostnames are particularly useful for an EKS-based architecture.

resource "aws_vpc" "terraform_vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.metadata, { Name = var.vpc_name })
}

########################## IGW FOR VPC ##########################

resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = merge(local.metadata, { Name = "${var.project_name}-igw" })

}


########################### SUBNETS FOR VPC ##########################

resource "aws_subnet" "terraform_public_subnet" {
  count = length(var.public_subnet_cidr_block)

  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = var.public_subnet_cidr_block[count.index]
  availability_zone       = var.ap_availability_zone[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.metadata, {
    Name                     = "${var.project_name}-public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  })

}

resource "aws_subnet" "terraform_private_subnet" {
  count = length(var.private_subnet_cidr_block)

  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = var.private_subnet_cidr_block[count.index]
  availability_zone = var.ap_availability_zone[count.index]

  tags = merge(local.metadata, {
    Name                              = "${var.project_name}-private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

############################ ROUTE TABLES FOR SUBNETS ##########################

# Public RT
resource "aws_route_table" "terraform_public_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  tags = merge(local.metadata, { Name = "${var.project_name}-public-rt" })

}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "terraform_public_subnet_association" {
  count = length(aws_subnet.terraform_public_subnet)

  subnet_id      = aws_subnet.terraform_public_subnet[count.index].id
  route_table_id = aws_route_table.terraform_public_rt.id
}

# Private RT
resource "aws_route_table" "terraform_private_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = merge(local.metadata, { Name = "${var.project_name}-private-rt" })

}

# Create a route in the private route table to direct traffic to the NAT Gateway
###  If private resources want to reach the internet, send that traffic to the NAT Gateway.  ###

resource "aws_route" "terraform_private_nat_route" {
  route_table_id         = aws_route_table.terraform_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.terraform_nat_gateway.id
}

# Associate the private subnets with the private route table
resource "aws_route_table_association" "terraform_private_subnet_association" {

  count          = length(aws_subnet.terraform_private_subnet)
  subnet_id      = aws_subnet.terraform_private_subnet[count.index].id
  route_table_id = aws_route_table.terraform_private_rt.id

}

############################ NAT GATEWAY FOR PRIVATE SUBNETS ##########################

# Elastic IP for the NAT Gateway
resource "aws_eip" "terraform_nat_eip" {
  domain = "vpc"

  tags = merge(local.metadata, { Name = "${var.project_name}-nat-eip" })

}

# NAT Gateway in the public subnet
resource "aws_nat_gateway" "terraform_nat_gateway" {
  allocation_id = aws_eip.terraform_nat_eip.id

  # NAT Gateway is placed in PUBLIC subnet
  subnet_id = aws_subnet.terraform_public_subnet[0].id

  tags = merge(local.metadata, { Name = "${var.project_name}-nat-gateway" })

  depends_on = [
    aws_internet_gateway.terraform_igw
  ]
}

