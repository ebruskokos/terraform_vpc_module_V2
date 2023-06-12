output "public_subnet_id" {
  value = aws_subnet.public.*.id
}

output "vpc_id" {
  value = aws_vpc.main.*.id
}

output "security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = aws_security_group.sg.*.id[0]
}
