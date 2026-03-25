resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "k8s-vpc"
  }
}

resource "aws_subnet" "k8s_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.k8s_vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.k8s_vpc.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "k8s_sg" {
  vpc_id = aws_vpc.k8s_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
