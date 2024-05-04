terraform {
  backend "s3" {
    bucket = "ansible-discovery"
    key = "infra-remote/tfstate"
    dynamodb_table = "ansible-discovery-table"
    region = "eu-west-1"
    encrypt = true
    profile = "LeadUser"
  }
}