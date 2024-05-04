locals {
  name = "ansible-discovery"
}

data "aws_acm_certificate" "cert" {
  domain      = "henrykingroyal.co"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

module "vpc" {
  source         = "./module/vpc"
  public-subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  azs            = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private-subnet = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

module "security_groups" {
  source = "./module/security-group"
  vpc-id = module.vpc.vpc
}

module "keypair" {
  source = "./module/keypair"
}

module "bastion" {
  source      = "./module/bastion"
  private_key = module.keypair.private_key_pem
  ami         = "ami-08e592fbb0f535224"
  subnet_id   = module.vpc.publicsub1
  bastion_sg  = module.security_groups.bastion-sg
  keyname     = module.keypair.keypair_Pub
  tag_bastion = "${local.name}-bastion"
}

module "jenkins" {
  source       = "./module/jenkins"
  ami          = "ami-08e592fbb0f535224"
  subnet-id    = module.vpc.privatesub1
  jenkins-sg   = module.security_groups.jenkins-sg
  key-name     = module.keypair.keypair_Pub
  jenkins-name = "${local.name}-jenkins"
  subnet-elb   = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  cert-arn     = data.aws_acm_certificate.cert.arn
  nexus-ip     = module.nexus.nexus-ip
  nr-key       = ""
  nr-acc-id    = ""
  nr-region    = ""
}

module "nexus" {
  source      = "./module/nexus"
  ami         = "ami-08e592fbb0f535224"
  keypair     = module.keypair.keypair_Pub
  nexus-sg    = module.security_groups.nexus-sg
  subnet_id   = module.vpc.publicsub3
  nexus-name  = "${local.name}-nexus"
  elb-subnets = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  cert-arn    = data.aws_acm_certificate.cert.arn
  nr-key      = ""
  nr-acc-id   = ""
  nr-region   = ""
}

module "sonarqube" {
  source         = "./module/sonarqube"
  ami            = "ami-0776c814353b4814d"
  keypair        = module.keypair.keypair_Pub
  sonarqube-sg   = module.security_groups.sonarqube-sg
  subnet_id      = module.vpc.publicsub2
  sonarqube-name = "${local.name}-sonarqube"
  elb-subnets    = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  cert-arn       = data.aws_acm_certificate.cert.arn
  nr-acc-id      = ""
  nr-key         = ""
  nr-region      = ""
}

