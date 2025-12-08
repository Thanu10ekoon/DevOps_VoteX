output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.votex_server.id
}

output "instance_public_ip" {
  description = "Public IP address of EC2 instance"
  value       = aws_eip.votex_eip.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of EC2 instance"
  value       = aws_instance.votex_server.public_dns
}

output "ssh_connection_command" {
  description = "SSH connection command"
  value       = "ssh -i ~/.ssh/votex_key ubuntu@${aws_eip.votex_eip.public_ip}"
}
