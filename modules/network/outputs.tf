output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_public_id" {
  value = aws_subnet.public.id
}

output "subnet_private_id" {
  value = aws_subnet.private.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

output "route_table_public_id" {
  value = aws_route_table.public.id
}

output "route_table_private_id" {
  value = aws_route_table.private.id
}

output "route_table_association_public_id" {
  value = aws_route_table_association.public.id
}

output "route_table_association_private_id" {
  value = aws_route_table_association.private.id
}

output "security_group_id" {
  value = aws_security_group.main.id
}

output "vpc_secrurity_group_egress_rule_id" {
  value = aws_vpc_security_group_egress_rule.main.id
}