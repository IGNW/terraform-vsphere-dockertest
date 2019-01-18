#output "dtr_url" {
#  value = "${module.dockeree-cluster.dtr_url}"
#}

#output "ucp_url" {
#  value = "${module.dockeree-cluster.ucp_url}"
#}

#output "manager_public_ips" {
#  value = "${module.dockeree-cluster.manager_public_ips}"
#}

#output "worker_public_ips" {
#  value = "${module.dockeree-cluster.worker_public_ips}"
#}

#output "dtr_public_ips" {
#  value = "${module.dockeree-cluster.dtr_public_ips}"
#}

output "minio_address" {
  value = "${module.dockeree-cluster.minio_address}"
}
