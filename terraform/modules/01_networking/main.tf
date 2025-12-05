# 1. VPC Creation
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_name}-VPC"
    Project = var.project_name
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-IGW"
  }
}

# 3. Subnets & NAT Gateways
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index) # 10.0.0.0/24, 10.0.1.0/24, etc.
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-Public-Subnet-${count.index + 1}"
    Tier    = "Public"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones)) # 10.0.2.0/24, 10.0.3.0/24, etc.
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name    = "${var.project_name}-Private-Subnet-${count.index + 1}"
    Tier    = "Private"
  }
}

# EIP for NAT Gateway (one EIP per AZ)
resource "aws_eip" "nat" {
  count = length(var.availability_zones)
  #vpc   = true
  tags = {
    Name = "${var.project_name}-NAT-EIP-${count.index + 1}"
  }
}

# NAT Gateway (one per AZ in the public subnet)
resource "aws_nat_gateway" "nat" {
  count         = length(var.availability_zones)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  
  tags = {
    Name = "${var.project_name}-NAT-Gateway-${count.index + 1}"
  }
  # Depends on the Internet Gateway being created first for the public route table
  depends_on = [aws_internet_gateway.igw] 
}

# 4. Route Tables

# Route Table for Public Subnets (direct access to IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "${var.project_name}-Public-RT"
  }
}

# Route Table for Private Subnets (routes outbound traffic through NAT)
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat.*.id, count.index)
  }

  tags = {
    Name = "${var.project_name}-Private-RT-${count.index + 1}"
  }
}

# 5. Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}