output "nexus-ip" {
  value = aws_instance.nexus_Server.public_ip
}
output "nexus-dns-name" {
  value = aws_elb.elb-nexus.dns_name
}
output "nexus-zone-id" {
  value = aws_elb.elb-nexus.zone_id
}