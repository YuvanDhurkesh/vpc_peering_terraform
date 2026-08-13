output "primary_public_ip" {
  value = aws_instance.primary_ec2.public_ip
}

output "primary_private_ip" {
  value = aws_instance.primary_ec2.private_ip
}

output "secondary_public_ip" {
  value = aws_instance.secondary_ec2.public_ip
}

output "secondary_private_ip" {
  value = aws_instance.secondary_ec2.private_ip
}

