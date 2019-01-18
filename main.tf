module "dockeree-cluster" {
  source                  = "modules/docker_cluster"

  environment             = "lab"
  vsphere_server          = "10.254.252.5"
  vsphere_datacenter      = "POC-Lab"
  vsphere_datastore       = "IGNW-POC"
  vsphere_compute_cluster = "POC"
  vsphere_network         = "ignw-poc|vesta-devops|servers"
  vsphere_folder          = "docker-ee"
  vm_template           = "ubuntu1604_dockeree_template"
  domain                  = "ignw.io"
  manager_node_count      = "2"
  worker_node_count       = "1"
  dtr_node_count          = "1"
  vsphere_user            = "administrator@vsphere.local"
  vsphere_password        = "${var.vsphere_password}"
  ssh_username            = "adminuser"
  ssh_password            = "${var.ssh_password}"
  ucp_admin_password      = "${var.ucp_admin_password}"
  ucp_version             = "3.0.3"
}