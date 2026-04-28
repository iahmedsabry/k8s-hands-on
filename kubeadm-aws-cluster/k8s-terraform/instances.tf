data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.k8s_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_nodes_sg.id]
  key_name               = aws_key_pair.k8s_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.k8s_node_profile.name

  tags = {
    Name = "k8s-master"
    "kubernetes.io/cluster/k8s-cluster" = "shared"
  }
}

resource "aws_instance" "workers" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.k8s_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_nodes_sg.id]
  key_name               = aws_key_pair.k8s_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.k8s_node_profile.name

  tags = {
    Name = "k8s-worker-${count.index}"
    "kubernetes.io/cluster/k8s-cluster" = "shared"
  }
}

