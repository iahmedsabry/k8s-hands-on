data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_vpc" "k8s_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name                                = "k8s-vpc"
    "kubernetes.io/cluster/k8s-cluster" = "shared"
  }
}

resource "aws_subnet" "k8s_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name                                = "k8s-subnet"
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
    Name                                = "k8s-subnet-2"
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

resource "aws_security_group" "k8s_nodes_sg" {
  name   = "k8s-nodes-sg"
  vpc_id = aws_vpc.k8s_vpc.id

  lifecycle {
    create_before_destroy = true
  }

  # Allow everything inside the cluster
  ingress {
    description = "Allow all between nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # SSH from your IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                                = "k8s-nodes-sg"
    "kubernetes.io/cluster/k8s-cluster" = "shared"
  }
}

resource "aws_security_group_rule" "alb_to_nodes" {
  type                     = "ingress"
  description              = "Allow ALB to reach NodePorts"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s_nodes_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}


resource "aws_security_group" "alb_sg" {
  name   = "k8s-alb-sg"
  vpc_id = aws_vpc.k8s_vpc.id

  # Internet → ALB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ALB → targets
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name                                = "alb-sg"
    "kubernetes.io/cluster/k8s-cluster" = "shared"

  }
}
