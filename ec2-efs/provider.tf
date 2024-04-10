terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.41"
    }
  }
  backend "s3" {
    bucket = "tfpocbucket001"
    key    = "ec2-efs/dev/terraform.tfstate"
    region = "eu-north-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-north-1"
  #access_key = "my-access-key" 
  #export AWS_ACCESS_KEY_ID="anaccesskey"
  #secret_key = "my-secret-key" 
  #export AWS_SECRET_ACCESS_KEY="asecretkey"
}
