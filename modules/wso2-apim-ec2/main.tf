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

resource "aws_instance" "this" {
  ami = data.aws_ami.amazon_ami.id
  instance_type = "t3a.medium"

  key_name = aws_key_pair.this.key_name


}