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
  azs            = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
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
  ami         = "ami-035cecbff25e0d91e"
  subnet_id   = module.vpc.publicsub1
  bastion_sg  = module.security_groups.bastion-sg
  keyname     = module.keypair.keypair_Pub
  tag_bastion = "${local.name}-bastion"
}

module "jenkins" {
  source       = "./module/jenkins"
  ami          = "ami-035cecbff25e0d91e"
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
  ami         = "ami-035cecbff25e0d91e"
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
  ami            = "ami-053a617c6207ecc7b"
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

module "ansible" {
  source                   = "./module/ansible"
  ami-redhat               = "ami-035cecbff25e0d91e"
  ansible-sg               = module.security_groups.ansible-sg
  key-name                 = module.keypair.keypair_Pub
  subnet-id                = module.vpc.privatesub2
  ansible-name             = "${local.name}-ansible-auto"
  staging-MyPlaybook       = "${path.root}/module/ansible/stage-playbook.yaml"
  prod-MyPlaybook          = "${path.root}/module/ansible/prod-playbook.yaml"
  staging-discovery-script = "${path.root}/module/ansible/stage-inventory-bash-script.sh"
  prod-discovery-script    = "${path.root}/module/ansible/prod-inventory-bash-script.sh"
  private_key              = module.keypair.private_key_pem
  nexus-ip                 = module.nexus.nexus-ip
  nr-key                   = ""
  nr-acc-id                = ""
  nr-region                = ""
}

module "stage-asg" {
  source = "./module/stage-asg"
  ami-stg = "ami-035cecbff25e0d91e"
  key-name = module.keypair.keypair_Pub
  asg-sg = module.security_groups.asg-sg
  nexus-ip-stg = module.nexus.nexus-ip
  nr-key-stg = ""
  nr-acc-id-stg = ""
  nr-region-stg = "EU"
  asg-stg-name = "${local.name}-stage-asg"
  vpc-zone-id-stg = [module.vpc.privatesub1, module.vpc.privatesub2, module.vpc.privatesub3]
  tg-arn = ""
}

module "prod-asg" {
  source = "./module/prod-asg"
  ami-prd = "ami-035cecbff25e0d91e"
  key-name = module.keypair.keypair_Pub
  asg-sg = module.security_groups.asg-sg
  nexus-ip-prd = module.nexus.nexus-ip
  nr-acc-id-prd = ""
  nr-key-prd = ""
  nr-region-prd = "EU"
  asg-prd-name = "${local.name}-prod-asg"
  vpc-zone-id-prd = [module.vpc.privatesub1, module.vpc.privatesub2, module.vpc.privatesub3]
  tg-arn = ""
}

