provider "aws" {
  profile = "default"
  region = "us-east-2"
  version = "~> 2.25"
}

module "wso2_apim_ec2" {
  source = "./modules/wso2-apim-ec2"
}

module "mitrai_setf_codepipeline" {
  source = "git::https://github.com/MitraInnovationRepo/terraform-aws-codepipeline.git?ref=tags/v0.2.2-lw"

  namespace = "SETF"
  name = "APITesting"
  stage = "DEV"
  tags = {
    Name: "SETF-WSO2-APIM-Testing"
  }

  github_organization = "MitraInnovationRepo"
  github_repository = "terraform-aws-api-newman-test"
  github_repository_branch = "develop"
  github_token = var.github_token
  github_webhook_events = [
    "push"
  ]
  webhook_filters = [
    {
      json_path = "$.ref"
      match_equals = "refs/heads/{Branch}"
    }
  ]

  codebuild_description = "SETF CodeBuild Sample Java Application"
  codebuild_build_environment_compute_type = "BUILD_GENERAL1_SMALL"
  codebuild_build_environment_image = "aws/codebuild/standard:1.0"
  codebuild_build_timeout = "5"

  codedeploy_deployment_config_name = "CodeDeployDefault.OneAtATime"
  codedeploy_ec2_tag_filters = [
    {
      key = "Name"
      value = "Test"
      type = "KEY_AND_VALUE"
    }
  ]
}
