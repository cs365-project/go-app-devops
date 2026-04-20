output "public_ip" {
  value = aws_instance.jump.public_ip
}

output "instance_id" {
  value = aws_instance.jump.id
}
