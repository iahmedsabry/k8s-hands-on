data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.k8s_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = aws_key_pair.k8s_key.key_name

  tags = {
    Name = "k8s-control-plane"
  }
}

resource "aws_instance" "workers" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.k8s_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = aws_key_pair.k8s_key.key_name

  tags = {
    Name = "k8s-worker-${count.index}"
  }
}

