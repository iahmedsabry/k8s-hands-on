data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

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
  availability_zone       = "us-east-1a"

  tags = {
    Name = "k8s-subnet"
    "kubernetes.io/cluster/k8s-cluster" = "shared"
    "kubernetes.io/role/elb"            = "1"
  }
}

resource "aws_subnet" "k8s_subnet_2" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b" # MUST be different than 1a

  tags = {
    Name = "k8s-subnet-2"
    "kubernetes.io/cluster/k8s-cluster" = "shared"
    "kubernetes.io/role/elb"            = "1"
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

resource "aws_route_table_association" "assoc_2" {
  subnet_id      = aws_subnet.k8s_subnet_2.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Kubernetes cluster security group"
  vpc_id      = aws_vpc.k8s_vpc.id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes NodePort range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes API Server (internal)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow all internal cluster communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Kubernetes API Server (Public Access)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    # Change this from 10.0.0.0/16 to allow your laptop
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"] # Or put your specific Public IP here for better security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-sg"
  }
}

resource "aws_route53_zone" "private" {
  name = "insightlab.internal"

  vpc {
    vpc_id = aws_vpc.k8s_vpc.id
  }

  tags = {
    Name = "k8s-private-zone"
    Environment = "dev"
    Project     = "k8s-hands-on"
  }
}

