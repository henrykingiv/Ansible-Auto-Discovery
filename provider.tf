provider "aws" {
  region  = "eu-west-2"
  profile = "LeadUser"
}

provider "vault" {
  token = "s.SeTBe2D1WjTFqOhTj8clkTzV"
  address = "https://vault.henrykingroyal.co/"
}