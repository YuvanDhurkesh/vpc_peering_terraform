terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  alias  = "secondary"
}
provider "aws" {
  region = "us-east-1"
  alias  = "primary"
}