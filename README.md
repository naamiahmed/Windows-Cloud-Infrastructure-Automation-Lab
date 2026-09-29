# Windows Cloud Infrastructure Automation Lab

Automated deployment of a cost-optimized Windows Server EC2 instance on AWS using Terraform.

## Architecture Overview

```text
Default VPC (Internet Gateway)
    │
    └── Windows Server EC2 (t3.micro, gp3 30GB)
            │
            ├── Security Group
            │     ├── Ingress: RDP (TCP :3389)
            │     ├── Ingress: HTTP (TCP :80)
            │     └── Egress: All traffic
            │
            └── IAM Role & Instance Profile
                  ├── CloudWatchAgentServerPolicy
                  └── AmazonSSMManagedInstanceCore
```

## Project Structure

```text
terraform/
├── provider.tf             # AWS provider configuration & default tags
├── variables.tf            # Parameterized inputs (region, instance type, CIDRs, etc.)
├── main.tf                 # Resources: VPC lookup, SG, IAM Role, EC2 Instance
├── outputs.tf              # Outputs (Public IP, DNS, SG ID, RDP command, etc.)
└── terraform.tfvars.example # Example variable definitions
```

## Cost Optimization Highlights

1. **Instance Type (`t3.micro`)**: Fits low-cost lab environments while providing burstable compute.
2. **Standard CPU Credit (`cpu_credits = "standard"`)**: Prevents unexpected burst surplus charges on T3 instances.
3. **Storage (`gp3`, 30 GB)**: GP3 provides baseline 3,000 IOPS and 125 MB/s throughput at a ~20% lower cost than gp2. 30 GB fits the Windows Server baseline and AWS Free Tier EBS allocation.
4. **Default VPC**: Avoids NAT Gateway (~$32+/month per AZ) and VPC Endpoint costs.
5. **No Elastic IP (EIP)**: Uses dynamic public IP auto-assignment, avoiding idle EIP charges.

## Quickstart

### 1. Authenticate to AWS
Terraform automatically detects credentials configured via AWS CLI:
```powershell
aws configure
```
Verify current identity:
```powershell
aws sts get-caller-identity
```

### 2. Configure Variables (Optional)
By default, Terraform will **automatically generate** an RSA key pair (`windows-server-lab-key`) and save `windows-key.pem` directly into your `terraform/` folder!
If you prefer using an existing EC2 key pair, copy the example variables file:
```powershell
cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars
```
And set `key_name = "your-existing-key-name"`.

### 3. Deploy
```powershell
terraform init
terraform plan
terraform apply
```

### 4. Connect to Windows Server
1. **Retrieve Password**:
   Wait ~4–5 minutes after instance launch for Windows initialization, then run:
   ```powershell
   aws ec2 get-password-data --instance-id <INSTANCE_ID> --priv-launch-key windows-key.pem
   ```
   *(Or in AWS Console: EC2 -> Instances -> Select Instance -> Actions -> Security -> Get Windows Password -> Upload `windows-key.pem`)*.
2. **Connect via RDP**:
   ```powershell
   mstsc /v:<INSTANCE_PUBLIC_IP>
   ```
   Log in with username `Administrator` and the decrypted password.

### 5. Cleanup
To stop incurring any charges:
```powershell
terraform destroy
```