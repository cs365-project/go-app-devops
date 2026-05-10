output "public_ip" {
  value = aws_instance.jump.public_ip
}

output "instance_id" {
  value = aws_instance.jump.id
}

output "security_group_id" {
  description = "Jump server security group ID"
  value       = aws_security_group.jump.id
}
