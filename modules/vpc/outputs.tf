
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private_subnets[*].id
}

output "private_route_table_id" {
  description = "Private routing table id"
  value       = aws_route_table.private.id
}
