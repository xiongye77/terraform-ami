# Create Bastion Host Security Group

resource "aws_security_group" "dfsc_bastion_sg" {
  vpc_id = aws_vpc.dfsc_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = {
    Name        = "DFSC Bastion Security Group"
    Terraform   = "true"
    } 
}


# CREATE BASTION HOST IN EU-WEST-1A PUBLIC SUBNET

resource "aws_instance" "dfsc_bastion_host-1a" {
  ami = "ami-06e488a5bdbcdb529"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ssh-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.dfsc_bastion_sg.id]
  subnet_id = aws_subnet.dfsc-public-1a.id
  tags = {
    Name = "DFSC Bastion Host - 1A"
    Terraform = true
  }
}

# CREATE BASTION HOST IN EU-WEST-1B PUBLIC SUBNET

resource "aws_instance" "dfsc_bastion_host-1b" {
  ami = "ami-055309b1e3b166cf3"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ssh-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.dfsc_bastion_sg.id]
  subnet_id = aws_subnet.dfsc-public-1b.id
  tags = {
    Name = "DFSC Bastion Host - 1B"
    Terraform = true
  }
}
