
resource "aws_security_group" "jenkins-SG" {
  name        = "jenkins-sg"
  description = "Allow TLS inbound traffic for jenkins"
  vpc_id      = var.vpc_id

  ingress {
    description = "8080 from VPC"
    from_port   = 22
    to_port     = 8080
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
    Name = "jenkins-sg"
  }
}
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048

}

resource "aws_key_pair" "mykey-1" {
  key_name   = "${var.namespace}-key"
  public_key = tls_private_key.this.public_key_openssh
}

resource "aws_efs_file_system" "this" {
  creation_token = "${var.namespace}-efs"

  tags = {
    Name = "${var.namespace}-efs"
  }
}
resource "aws_efs_mount_target" "this" {
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.jenkins-SG.id]
}

resource "aws_efs_access_point" "test" {
  file_system_id = aws_efs_file_system.this.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "jenkins" {
  ami                         = "ami-0fb653ca2d3203ac1"
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name                    = aws_key_pair.mykey-1.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins-SG.id]
  subnet_id                   = var.subnet_id
  user_data                   = local.user_data

  tags = {
    Name = "jenkins-server"
  }
}

resource "aws_instance" "jenkins_node" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name                    = aws_key_pair.mykey-1.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins-SG.id]
  subnet_id                   = var.subnet_id
  user_data                   = local.user_data_node
  tags = {
    Name = "${var.namespace}-node"
  }
}


