provider "aws" {
  profile = "default"
  region = "us-east-2"
  version = "~> 2.25"
}

module "wso2_apim_ec2" {
  source = "./modules/wso2-apim-ec2"
}