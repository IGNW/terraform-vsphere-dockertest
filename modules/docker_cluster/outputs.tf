#output "manager_public_ips" {
#  value = "${concat(module.docker-manager-primary.public_ips, module.docker-manager.public_ips)}"
#}

#output "worker_public_ips" {
#  value = "${module.docker-worker.public_ips}"
#}

#output "dtr_public_ips" {
#  value = "${module.docker-dtr.public_ips}"
#}

output "minio_address" {
  value = "${module.minio.public_ip}"
}

#output "ucp_url" {
#  value = "https://${module.docker-manager-primary.public_ips[0]}"
#}

#output "dtr_url" {
#  value = "https://${module.docker-dtr.public_ips[0]}"
#}
