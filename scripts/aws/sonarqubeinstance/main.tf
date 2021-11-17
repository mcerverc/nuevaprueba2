provider "aws" {
  region = var.aws_region

}

#create VPC
resource "aws_vpc" "sq_vpc" {
  cidr_block = var.vpc_cdir_block


  tags = {
    Name = "sqvpc"
  }
}

#creat internet gateway
resource "aws_internet_gateway" "sq_gateway" {
  vpc_id = aws_vpc.sq_vpc.id

  tags = {
    Name = "sqinternetgateway"
  }
}

#create costum route table
resource "aws_route_table" "sqrouttable" {
  vpc_id = aws_vpc.sq_vpc.id

  tags = {
    Name = "sqrouttable"
  }
}

resource "aws_route" "sqroute" {
  route_table_id         = aws_route_table.sqrouttable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.sq_gateway.id


}

#create subnet
resource "aws_subnet" "subnet_sq" {
  vpc_id     = aws_vpc.sq_vpc.id
  cidr_block = var.subnet_cdir_block


  tags = {
    Name = "sqsubnet"
  }
}
#routtable assoiation
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_sq.id
  route_table_id = aws_route_table.sqrouttable.id

  
}

#create securitygroup
resource "aws_security_group" "allow_web_sq" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.sq_vpc.id
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Port9000"
    from_port   = 9000
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "sqsecuritygroup"
  }
}

#networkinterface
resource "aws_network_interface" "sqnic" {
  subnet_id       = aws_subnet.subnet_sq.id
  private_ips     = [var.nic_privat_ip]   
  security_groups = [aws_security_group.allow_web_sq.id]


  tags = {
    Name = "sqnic"
  }
}

#elastic Ip Adress
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.sqnic.id
  associate_with_private_ip = var.nic_privat_ip 
  depends_on                = [aws_internet_gateway.sq_gateway]
}

#ubuntu server
resource "aws_instance" "sq-server" {
  ami = var.aim_ubuntu_20_04 
  instance_type = var.instance_type
  key_name      = var.key_name


  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.sqnic.id
  }


  #auto script for instalation docker
  user_data = file("./datascript.sh")
 
  tags = {
    Name = "sqserver"
  }
}


#outputs
output "elastic-IP" {
  value = aws_eip.one.public_ip
}

