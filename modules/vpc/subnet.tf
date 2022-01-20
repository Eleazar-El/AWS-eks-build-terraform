#---------------------------------
# Public subnet and route
#---------------------------------
 
resource "aws_subnet" "public_subnets" {
  vpc_id     = aws_vpc.main.id
  count      = local.public_subnet_count
  cidr_block = cidrsubnet(var.cidr_block, var.subnet_new_bits, count.index)
  availability_zone       = element(local.azs_list, count.index % local.azs_count)
  map_public_ip_on_launch = true
  tags = {
    Name  = "public-${element(local.azs_list, count.index)}-${count.index}"
    "kubernetes.io/cluster/gatsby-cluster"  = "shared"
    "kubernetes.io/role/elb"    = 1
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  count  = local.public_network_for_count
  tags = {
    Name        = "${var.environment}-rtb-public"
  }
}

resource "aws_route" "public" {
  count                  = local.public_network_for_count
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public[0].id
}



resource "aws_route_table_association" "public_subnets" {
  count          = local.public_subnet_count
  route_table_id = aws_route_table.public[0].id
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
}

#--------------------------------------
# Private Subnets and route
#--------------------------------------

resource "aws_subnet" "private_subnets" {
  vpc_id     = aws_vpc.main.id
  count      = local.private_subnet_count
  cidr_block = cidrsubnet(
    var.cidr_block,
    var.subnet_new_bits,
    local.public_subnet_count + count.index,
  )
  availability_zone = element(local.azs_list, count.index % local.azs_count)
  tags = {
    Name  = "private-{element(local.azs_list, count.index % local.azs_count)}-${count.index}"
    "kubernetes.io/cluster/gatsby-cluster"  = "shared"
    "kubernetes.io/role/internal-elb"  = "1"
  }
}

resource "aws_route_table" "private" {
  vpc_id  = aws_vpc.main.id
  tags    = {
    Name    = "${var.environment}-rtb-private"
    Region  = var.region
  }
}

resource "aws_route" "private" {
  count                  = local.public_network_for_count
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.private[0].id
}

resource "aws_main_route_table_association" "private" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.private.id
}

