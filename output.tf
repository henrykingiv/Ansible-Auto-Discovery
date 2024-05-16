output "nexus-ip" {
  value = module.nexus.nexus-ip
}
output "sonarqube-ip" {
  value = module.sonarqube.sonarqube-ip
}
output "jenkins" {
  value = module.jenkins.jenkins-ip
}
output "bastion" {
  value = module.bastion.bastion-ip
}
output "db-endpoint" {
  value = module.az-db.db-endpoint
}
output "ansible-ip" {
  value = module.ansible.ansible_ip
}