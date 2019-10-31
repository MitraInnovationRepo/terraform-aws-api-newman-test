data "aws_ami" "amazon_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["137112412989"] // amazon = 137112412989
}

resource "aws_key_pair" "this" {
  key_name = "wso2-apim-aws"
  public_key = file("./resources/ssh-key/wso2-apim-aws.pub")
}

resource "aws_security_group" "this" {
  name = "SETF-wso2-apim-security-group"
  description = "Default security group that allows inbound and outbound traffic from all instances in the VPC"

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
  egress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SETF-WSO2-APIM-Security-Group"
  }
}

resource "aws_instance" "this" {
  ami = data.aws_ami.amazon_ami.id
  instance_type = "t3a.medium"

  key_name = aws_key_pair.this.key_name

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
      "docker run -it -p 8280:8280 -p 8243:8243 -p 9443:9443 --name api-manager wso2am:2.6.0-alpine",
    ]
  }

  tags = {
    Name = "SETF-WSO2-APIM"
  }
}