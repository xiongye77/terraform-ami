# Define VPC Variable

variable "aws-vpc-cidr" {
  type= string
  default="10.0.0.0/16"
}

# Create VPC

resource "aws_vpc" "dfsc_vpc" {
  cidr_block = var.aws-vpc-cidr
  instance_tenancy = "default"
  tags = {
    Name = "DFSC VPC"
    Terrafrom = "True"
  }
}
# Create and Attach internet gateway

resource "aws_internet_gateway" "dfsc-igw" {
  vpc_id = aws_vpc.dfsc_vpc.id
  tags = {
    Name        = "DFSC Internet Gateway"
    Terraform   = "true"
  }
}
# CREATE ELASTIC IP ADDRESS FOR NAT GATEWAY

  resource "aws_eip" "dfsc-nat1" {
}
  resource "aws_eip" "dfsc-nat2" {
}
  

# CREATE NAT GATEWAY in EU-West-1A

resource "aws_nat_gateway" "dfsc-nat-gateway-1a" {
  allocation_id = aws_eip.dfsc-nat1.id
  subnet_id     = aws_subnet.dfsc-public-1a.id

  tags = {
    Name        = "Nat Gateway-1a"
    Terraform   = "True"
  }
}

# CREATE NAT GATEWAY in EU-West-1B

resource "aws_nat_gateway" "dfsc-nat-gateway-1b" {
  allocation_id = aws_eip.dfsc-nat2.id
  subnet_id     = aws_subnet.dfsc-public-1b.id

  tags = {
    Name        = "Nat Gateway-1b"
    Terraform   = "True"
  }
}
# Create Public Subnets

resource "aws_subnet" "dfsc-public-1a" {
  vpc_id = aws_vpc.dfsc_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Name        = "DFSC Pblic Subnet - 1A"
    Terraform   = "True"
  }
}
resource "aws_subnet" "dfsc-public-1b" {
  vpc_id = aws_vpc.dfsc_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"
  tags = {
    Name        = "DFSC Pblic Subnet - 1B"
    Terraform   = "True"
  }
}


# Create Private Subnets


resource "aws_subnet" "dfsc-private-1a" {
  vpc_id = aws_vpc.dfsc_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "false"
  tags = {
    Name        = "DFSC Private Subnet - 1A"
    Terraform   = "True"
  }
}

resource "aws_subnet" "dfsc-private-1b" {
  vpc_id = aws_vpc.dfsc_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "false"
  tags = {
    Name        = "DFSC Private Subnet - 1B"
    Terraform   = "True"
  }
}
# Create first private route table and associate it with private subnet in eu-west-1a
 
resource "aws_route_table" "dfsc_private_route_table_1a" {
    vpc_id = aws_vpc.dfsc_vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dfsc-nat-gateway-1a.id
  }
    tags =  {
        Name      = "DFSC Private route table 1A"
        Terraform = "True"
  }
}
 
resource "aws_route_table_association" "dfsc-1a" {
    subnet_id = aws_subnet.dfsc-private-1a.id
    route_table_id = aws_route_table.dfsc_private_route_table_1a.id
}
 
# Create second private route table and associate it with private subnet in eu-west-1b 
 
resource "aws_route_table" "dfsc_private_route_table_1b" {
    vpc_id = aws_vpc.dfsc_vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dfsc-nat-gateway-1b.id
  }
    tags =  {
        Name      = "DFSC Private route table 1B"
        Terraform = "True"
  }
}
 
resource "aws_route_table_association" "dfsc-1b" {
    subnet_id = aws_subnet.dfsc-private-1b.id
    route_table_id = aws_route_table.dfsc_private_route_table_1b.id
}

# Create a public route table for Public Subnets

resource "aws_route_table" "dfsc-public" {
  vpc_id = aws_vpc.dfsc_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dfsc-igw.id
  }
  tags = {
    Name        = "DFSC Public Route Table"
    Terraform   = "true"
    }
}

# Attach a public route table to Public Subnets

resource "aws_route_table_association" "dfsc-public-1a-association" {
  subnet_id = aws_subnet.dfsc-public-1a.id
  route_table_id = aws_route_table.dfsc-public.id
}

resource "aws_route_table_association" "dfsc-public-1b-association" {
  subnet_id = aws_subnet.dfsc-public-1b.id
  route_table_id = aws_route_table.dfsc-public.id
}
