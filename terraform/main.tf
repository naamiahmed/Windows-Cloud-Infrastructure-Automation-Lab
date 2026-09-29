# ==============================================================================
# DATA SOURCES: Default VPC, Subnets, and Latest Windows Server AMI
# ==============================================================================

# Look up default VPC to avoid NAT Gateway or VPC Endpoint costs
data "aws_vpc" "default" {
  default = true
}

# Look up subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Dynamic AMI lookup for official Windows Server 2022 Base AMI
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==============================================================================
# SECURITY GROUP: RDP (3389) and HTTP (80)
# ==============================================================================

resource "aws_security_group" "windows_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security group for Windows Server EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  # Ingress: Remote Desktop Protocol (RDP)
  ingress {
    description = "Allow RDP traffic"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allowed_rdp_cidr
  }

  # Ingress: HTTP Web Traffic
  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  # Egress: Full outbound access for Windows updates, packages, and CloudWatch metrics
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

# ==============================================================================
# IAM ROLE & INSTANCE PROFILE: CloudWatch & SSM Support
# ==============================================================================

# Trust policy allowing EC2 service to assume this role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Role for EC2
resource "aws_iam_role" "windows_role" {
  name               = "${var.instance_name}-iam-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.instance_name}-iam-role"
  }
}

# Attach AWS CloudWatch Agent policy for logs and metrics
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.windows_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach AWS SSM Managed Instance policy for Systems Manager / Fleet Manager connectivity
resource "aws_iam_role_policy_attachment" "ssm_managed_policy" {
  role       = aws_iam_role.windows_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile required to attach the role to the EC2 instance
resource "aws_iam_instance_profile" "windows_profile" {
  name = "${var.instance_name}-instance-profile"
  role = aws_iam_role.windows_role.name

  tags = {
    Name = "${var.instance_name}-instance-profile"
  }
}

# ==============================================================================
# KEY PAIR: Auto-generate RSA key pair & save local .pem if not supplied
# ==============================================================================

# Generates an RSA private key
resource "tls_private_key" "windows_key" {
  count     = var.key_name == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Registers the generated public key with AWS EC2
resource "aws_key_pair" "windows_key" {
  count      = var.key_name == "" ? 1 : 0
  key_name   = "${var.instance_name}-key"
  public_key = tls_private_key.windows_key[0].public_key_openssh

  tags = {
    Name = "${var.instance_name}-key"
  }
}

# Saves the private key to a local .pem file for decrypting the Windows Administrator password
resource "local_file" "windows_key_pem" {
  count           = var.key_name == "" ? 1 : 0
  content         = tls_private_key.windows_key[0].private_key_pem
  filename        = "${path.module}/windows-key.pem"
  file_permission = "0400"
}

# ==============================================================================
# EC2 INSTANCE: Windows Server
# ==============================================================================

resource "aws_instance" "windows_server" {
  ami                         = data.aws_ami.windows.id
  instance_type               = var.instance_type
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.windows_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.windows_profile.name
  key_name                    = var.key_name != "" ? var.key_name : aws_key_pair.windows_key[0].key_name
  associate_public_ip_address = true

  # Cost Optimization: Standard CPU credit specification avoids Unlimited burst surcharges
  credit_specification {
    cpu_credits = "standard"
  }

  # Cost Optimization: gp3 EBS volume (30 GB minimum for Windows Server, within free tier limits)
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.instance_name}-root-volume"
    }
  }

  tags = {
    Name = var.instance_name
  }
}
