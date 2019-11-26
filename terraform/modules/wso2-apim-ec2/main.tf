data "aws_ami" "amazon_ami" {
  most_recent = true

  filter {
    name = "name"
    values = [
      "amzn2-*"]
  }

  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }

  filter {
    name = "architecture"
    values = [
      "x86_64"]
  }

  owners = [
    "137112412989"]
  // amazon = 137112412989
}

# VPC
resource "aws_vpc" "this" {
  cidr_block = "10.1.0.0/16"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  instance_tenancy = "default"
  tags = {
    name: "SETF-WSO2-VPC"
  }
}

resource "aws_subnet" "public" {
  cidr_block = "10.1.1.0/24"
  vpc_id = aws_vpc.this.id
  availability_zone = "us-east-2a"
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  //  tags = var.tags
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id
  //  tags = var.tags

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "this" {
  route_table_id = aws_route_table.this.id
  subnet_id = aws_subnet.public.id
}

resource "aws_key_pair" "this" {
  key_name = "wso2-apim-aws"
  public_key = file("./resources/ssh-key/wso2-apim-aws.pub")
}

resource "aws_security_group" "this" {
  name = "SETF-wso2-apim-security-group"
  description = "Default security group that allows inbound and outbound traffic from all instances in the VPC"

  vpc_id = aws_vpc.this.id

  ingress {
    from_port = "8280"
    to_port = "8280"
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
    self = true
  }

  ingress {
    from_port = "8243"
    to_port = "8243"
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
    self = true
  }

  ingress {
    from_port = "9443"
    to_port = "9443"
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
    self = true
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
    self = true
  }
  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    Name = "SETF-WSO2-APIM-Security-Group"
  }
}

data "aws_eip" "this" {
  tags = {
    Name = "SETF-WSO2-APIM-EIP"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id = aws_instance.this.id
  allocation_id = data.aws_eip.this.id
  private_ip_address = "10.1.1.10"

  depends_on = [
    "aws_internet_gateway.this"
  ]
}

resource aws_eip "this" {
  vpc = true

}

resource "aws_instance" "this" {
  ami = data.aws_ami.amazon_ami.id
  instance_type = "t3a.medium"

  key_name = aws_key_pair.this.key_name
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
  subnet_id = aws_subnet.public.id
  associate_public_ip_address = "true"
  private_ip = "10.1.1.10"

  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
    delete_on_termination = true
    encrypted = false
  }

  connection {
    type = "ssh"
    user = "ec2-user"
    host = aws_instance.this.public_dns
    private_key = file("resources/ssh-key/wso2-apim-aws")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install -y docker",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y git",
      "git clone https://github.com/wso2/docker-apim.git",
      "cd docker-apim/",
      "git fetch --tags",
      "git checkout tags/v2.6.0.7 -b apim",
      "cd dockerfiles/alpine/apim",
      "docker build -t wso2am:2.6.0-alpine .",
      "docker run -dt -p 8280:8280 -p 8243:8243 -p 9443:9443 --name api-manager wso2am:2.6.0-alpine",
    ]
  }

  tags = {
    Name = "SETF-WSO2-APIM"
  }
}