locals {
  name = "ansible-discovery"
}

# data "vault_generic_secret" "vault-secret" {
#   path = "secret/database"
# }

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
  nr-key       = "NRAK-L7K04IRWOENEK2OOEWZI4W1G5ZL"
  nr-acc-id    = "4246321"
  nr-region    = "EU"
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
  nr-key      = "NRAK-L7K04IRWOENEK2OOEWZI4W1G5ZL"
  nr-acc-id   = "4246321"
  nr-region   = "EU"
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
  nr-acc-id      = "4246321"
  nr-key         = "NRAK-L7K04IRWOENEK2OOEWZI4W1G5ZL"
  nr-region      = "EU"
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
  nr-key                   = "NRAK-L7K04IRWOENEK2OOEWZI4W1G5ZL"
  nr-acc-id                = "4246321"
  nr-region                = "EU"
}

module "stage-asg" {
  source          = "./module/stage-asg"
  ami-stg         = "ami-035cecbff25e0d91e"
  key-name        = module.keypair.keypair_Pub
  asg-sg          = module.security_groups.asg-sg
  nexus-ip-stg    = module.nexus.nexus-ip
  nr-key-stg      = "NRAK-L7K04IRWOENEK2OOEWZI4W1G5ZL"
  nr-acc-id-stg   = "4246321"
  nr-region-stg   = "EU"
  asg-stg-name    = "${local.name}-stage-asg"
  vpc-zone-id-stg = [module.vpc.privatesub1, module.vpc.privatesub2, module.vpc.privatesub3]
  tg-arn          = module.stage-lb.stage-tg-arn
}

module "prod-asg" {
  source          = "./module/prod-asg"
  ami-prd         = "ami-035cecbff25e0d91e"
  key-name        = module.keypair.keypair_Pub
  asg-sg          = module.security_groups.asg-sg
  nexus-ip-prd    = module.nexus.nexus-ip
  nr-acc-id-prd   = "4246321"
  nr-key-prd      = "NRAK-L7K04IRWOENEK2OOEWZI4W1G5ZL"
  nr-region-prd   = "EU"
  asg-prd-name    = "${local.name}-prod-asg"
  vpc-zone-id-prd = [module.vpc.privatesub1, module.vpc.privatesub2, module.vpc.privatesub3]
  tg-arn          = module.prod-lb.prod-tg-arn
}

module "stage-lb" {
  source = "./module/stage-lb"
  vpc_id = module.vpc.vpc
  stage-sg = [module.security_groups.asg-sg]
  stage-subnet = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  stage-alb-name = "${local.name}-stage-lb"
  certificate_arn = data.aws_acm_certificate.cert.arn
}

module "prod-lb" {
  source = "./module/prod-lb"
  vpc_id = module.vpc.vpc
  prod-sg = [module.security_groups.asg-sg]
  prod-subnet = [module.vpc.publicsub1, module.vpc.publicsub2, module.vpc.publicsub3]
  prod-alb-name = "${local.name}-prod-lb"
  certificate_arn = data.aws_acm_certificate.cert.arn
}

data "aws_secretsmanager_secret" "db_credentials" {
  name = "MyDatabaseCredentials"
}

data "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

module "az-db" {
  source = "./module/az-db"
  db_subnet_grp = "db-subnetgrp"
  subnet = [module.vpc.privatesub1, module.vpc.privatesub2, module.vpc.privatesub3]
  tag-db-subnet = "${local.name}-az-db"
  security_group_mysql_sg = module.security_groups.rds-sg
  db_name = "petclinic"
  db_username = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string)["username"]
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string)["password"]
  #db_username = data.vault_generic_secret.vault-secret.data["username"]
  #db_password = data.vault_generic_secret.vault-secret.data["password"]
}

module "route53" {
  source = "./module/route53"
  domain_name = "henrykingroyal.co"
  jenkins_domain_name = "jenkins.henrykingroyal.co"
  jenkins_lb_dns_name = module.jenkins.jenkins-dns-name
  jenkins_lb_zone_id = module.jenkins.jenkins-zone-id
  nexus_domain_name = "nexus.henrykingroyal.co"
  nexus_lb_dns_name = module.nexus.nexus-dns-name
  nexus_lb_zone_id = module.nexus.nexus-zone-id
  sonarqube_domain_name = "sonarqube.henrykingroyal.co"
  sonarqube_lb_dns_name = module.sonarqube.sonarqube-dns-name
  sonarqube_lb_zone_id = module.sonarqube.sonarqube-zone-id
  prod_domain_name = "prod.henrykingroyal.co"
  prod_lb_dns_name = module.prod-lb.prod-lb-dns
  prod_lb_zone_id = module.prod-lb.prod-lb-zone-id
  stage_domain_name = "stage.henrykingroyal.co"
  stage_lb_dns_name = module.stage-lb.stage-lb-dns
  stage_lb_zone_id = module.stage-lb.stage-lb-zone-id
}

