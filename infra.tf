resource "aws_vpc" "vpc" {
  cidr_block = "${var.ipaddress}.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Simple-VPC"

    #Environment = var.infra_env
    ManagedBy = "terraform"
  }
}

# ==== GATEWAYS ====
# Internet Gateway
resource "aws_internet_gateway" "TF_IGW" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "TF_IGW"
  }
}

# ===== NAT GATEWAY ====
resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "nat_gateway"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.TF_IGW]
}
# =======

#==== ROUTE TABLES ====
# Route table: attach Internet Gateway 
resource "aws_route_table" "Public_RT" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TF_IGW.id
  }
  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table" "Private_RT" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "Private_RT"
  }
}
# ========


# ==== NACLS =====
resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = [ aws_subnet.public.id ]

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  #allow ssh
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  
#allow ephemeral ports
ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
# HTTPS
  # ingress {
  #   protocol   = "tcp"
  #   rule_no    = 300
  #   action     = "allow"
  #   cidr_block = "0.0.0.0/0"
  #   from_port  = 443
  #   to_port    = 443
  # }
# HTTP
  # ingress {
  #   protocol   = "tcp"
  #   rule_no    = 400
  #   action     = "allow"
  #   cidr_block = "0.0.0.0/0"
  #   from_port  = 80
  #   to_port    = 80
  # }
  tags = {
    Name = "main"
  }
}
# ========


# ==== SUBNETS + RT ASSOCIATIONS + OUTPUTS  ====
resource "aws_subnet" "public" {
  
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone = var.az # allow others easy finding of AZ

  # 2,048 IP addresses each
  cidr_block = "${var.ipaddress}.1.0/24"

  tags = {
    Name = "Public Subnet"
    Role = "Main_Public"
    ManagedBy = "terraform"

  }
}

# Route table association with  Public Subnet
resource "aws_route_table_association" "Internet_gateway" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.Public_RT.id
}

#standard private subnet
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.vpc.id
  # 2,048 IP addresses each
  cidr_block = "${var.ipaddress}.2.0/24"

  tags = {
    Name = "Private"
    Role = "Private"
    ManagedBy = "terraform"

  }
}

# Route table association with private subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.Private_RT.id
}

output "public_subnet" {
  value = aws_subnet.public.cidr_block
}

output "private_subnet" {
  value = aws_subnet.private.cidr_block
}


#===== Security Groups ====== #
resource "aws_security_group" "SG_Public" {
  description = "SSH open to world"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # 80
  #  ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # #HTTPS
  #  ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Public_SG"
  }
}


resource "aws_security_group" "SG_Private" {
  name        = "SG_Private"
  description = "private security group"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 1
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [aws_security_group.SG_Public.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG_Private"
  }
}

resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.private.id]

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
#allow traffic from Public Subnet
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "${var.ipaddress}.1.0/24"
    from_port  = 0
    to_port    = 0
  }
   #allow ephemeral ports
ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  tags = {
    Name = "private"
  }
}





