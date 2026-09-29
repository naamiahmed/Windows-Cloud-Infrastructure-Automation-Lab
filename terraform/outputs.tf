output "instance_id" {
  description = "The ID of the Windows Server EC2 instance"
  value       = aws_instance.windows_server.id
}

output "instance_public_ip" {
  description = "Public IPv4 address of the Windows Server"
  value       = aws_instance.windows_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the Windows Server"
  value       = aws_instance.windows_server.public_dns
}

output "security_group_id" {
  description = "Security Group ID protecting the instance"
  value       = aws_security_group.windows_sg.id
}

output "iam_role_arn" {
  description = "ARN of the IAM Role attached to the instance for CloudWatch"
  value       = aws_iam_role.windows_role.arn
}

output "rdp_connection_command" {
  description = "Command to initiate Remote Desktop connection on Windows"
  value       = "mstsc /v:${aws_instance.windows_server.public_ip}"
}

output "key_pair_name" {
  description = "The EC2 Key Pair associated with the Windows instance"
  value       = var.key_name != "" ? var.key_name : aws_key_pair.windows_key[0].key_name
}

output "private_key_file" {
  description = "Path to the generated private key (.pem) used to decrypt the Administrator password"
  value       = var.key_name == "" ? "${path.module}/windows-key.pem" : "Using pre-existing key pair: ${var.key_name}"
}

output "get_password_command" {
  description = "AWS CLI command to retrieve and decrypt the Windows Administrator password"
  value       = var.key_name == "" ? "aws ec2 get-password-data --instance-id ${aws_instance.windows_server.id} --priv-launch-key windows-key.pem" : "aws ec2 get-password-data --instance-id ${aws_instance.windows_server.id} --priv-launch-key <path-to-${var.key_name}.pem>"
}
