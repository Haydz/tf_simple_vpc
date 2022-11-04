provider "aws" {
  region = "ca-central-1"
}
# ===
# System in Public Subnet
resource "aws_instance" "public_test_instance" {
  ami                  = "ami-088d4832275406edf" # Amazon Linux 2 Kernel 5.10 AMI 2.0.20221004.0 x86_64 HVM gp2
  subnet_id            = aws_subnet.public.id
  security_groups      = [aws_security_group.SG_Public.id]
  instance_type        = "t3.micro"
  user_data            = file("amznlinx_update.sh") # Update server
  key_name             = var.sshkey
  tags = {
    Name = "Public-Instance-Test"
  }
}
output "public_test_instance_ID" {
  value = aws_instance.public_test_instance.id
}
output "public_test_instance_IP" {
  value = aws_instance.public_test_instance.public_ip
}
output "public_test_instance_Private_IP" {
  value = aws_instance.public_test_instance.private_ip
}

# System in Private subnet
resource "aws_instance" "private_test_instance" {
  ami                  = "ami-088d4832275406edf" # Amazon Linux 2 Kernel 5.10 AMI 2.0.20221004.0 x86_64 HVM gp2
  subnet_id            = aws_subnet.private.id
  security_groups      = [aws_security_group.SG_Private.id]
  instance_type        = "t3.micro"
  iam_instance_profile = "EC2SSMRole" # An SSM role to allow SSM System Session
  key_name             = var.sshkey
  user_data            = file("amznlinx_update.sh") # Update server 
  tags = {
    Name = "Private-Instance-Test"
  }
}
output "private_test_instance_ID" {
  value = aws_instance.private_test_instance.id
}
output "private_test_instance_Private_IP" {
  value = aws_instance.private_test_instance.private_ip
}