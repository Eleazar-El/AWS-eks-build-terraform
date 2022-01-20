data "aws_availability_zones" "available" {
}

locals {
  azs_list  = data.aws_availability_zones.available.names
  azs_count = length(data.aws_availability_zones.available.names)
  public_subnet_count      = var.public_subnet_count >= 0 ? var.public_subnet_count : local.azs_count
  private_subnet_count     = var.private_subnet_count >= 0 ? var.private_subnet_count : local.azs_count
  public_network_for_count = local.public_subnet_count > 0 ? 1 : 0
}

resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name          = "${var.environment}-vpc-${var.region}"
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.main.id
  count  = local.public_network_for_count
  tags = {
    Name        = "${var.environment}-igw-public"
  }
}

resource "aws_eip" "nat_gateway" {
  vpc   = true
  count = local.public_network_for_count
  tags  = {
    Name  = "${var.environment}-eip-nat-gateway"
  }
  depends_on = [aws_internet_gateway.public]
}

resource "aws_nat_gateway" "private" {
  count         = local.public_network_for_count
  allocation_id = aws_eip.nat_gateway[0].id
  subnet_id     = aws_subnet.public_subnets[0].id
  tags = {
    Name        = "${var.environment}-nat-private"
  }
  depends_on    = [aws_internet_gateway.public]
}

resource "aws_cloudwatch_log_group" "vpc_traffic" {
  name              = "${var.environment}-${aws_vpc.main.id}-flowlogs"
  retention_in_days = 365
}