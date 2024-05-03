output "sonarqube-ip" {
  value = aws_instance.SonarQube_Server.public_ip
}
output "sonarqube-dns-name" {
  value = aws_elb.elb-sonar.dns_name
}
output "sonarqube-zone-id" {
  value = aws_elb.elb-sonar.zone_id
}