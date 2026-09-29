variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS CLI profile name to use for authentication (leave empty to use default AWS credentials)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "instance_name" {
  description = "Name tag for the Windows EC2 instance and associated resources"
  type        = string
  default     = "windows-server-lab"
}

variable "instance_type" {
  description = "EC2 instance type (cost-optimized t3.micro)"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional name of an existing EC2 Key Pair. If left empty (''), Terraform will automatically generate a new RSA Key Pair and save 'windows-key.pem' locally."
  type        = string
  default     = ""
}

variable "allowed_rdp_cidr" {
  description = "CIDR block permitted for RDP (port 3389). For security, restrict to your public IP (e.g., ['x.x.x.x/32'])"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidr" {
  description = "CIDR block permitted for HTTP (port 80)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB (Windows Server requires at least 30 GB)"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root EBS volume type (gp3 offers baseline 3000 IOPS and is ~20% cheaper than gp2)"
  type        = string
  default     = "gp3"
}
