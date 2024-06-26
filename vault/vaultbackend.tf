terraform {
  backend "s3" {
    bucket         = "ansible-discovery-env"
    key            = "vault-remote/tfstate"
    dynamodb_table = "ansible-discovery-table"
    region         = "eu-west-2"
    encrypt        = true
    profile        = "LeadUser"
  }
}