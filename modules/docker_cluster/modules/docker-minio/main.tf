locals {
  name        = "docker-${var.environment}-minio"
  disk_dev    = "/dev/xvdf"
  minio_port  = 9000
}

resource "random_string" "minio_access_key" {
  length = 20
  special = false
}

resource "random_string" "minio_secret_key" {
  length = 40
  special = false
}

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_datastore" "datastore" {
  name          = "${var.vsphere_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "${var.vsphere_compute_cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "${var.vsphere_network}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

variable "domain" {
  description = "Domain name"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.vm_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "minio" {

  name               = "${local.name}"
  folder             = "${var.vsphere_folder}"
  resource_pool_id   = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id       = "${data.vsphere_datastore.datastore.id}"

  num_cpus = "${var.node_vcpu}"
  memory = "${var.node_memory}"
  memory_reservation = "${var.node_memory}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  network_interface {
      network_id = "${data.vsphere_network.network.id}"
  }
  disk {
      label = "disk0"
      size  = "${var.root_volume_size}"
  }

  clone {
      template_uuid = "${data.vsphere_virtual_machine.template.id}"

      customize {
        linux_options {
          host_name = "${local.name}"
          domain    = "${var.domain}"
        }
        network_interface {}
        dns_server_list = ["8.8.8.8"]
        dns_suffix_list = ["${var.domain}"]
    }
  }

# Run the configuration script
provisioner "remote-exec" {
  connection = {
  type = "ssh"
  user = "${var.ssh_username}"
  password = "${var.ssh_password}"
}
inline = [
<<EOT
set -x

# mount network storage
sudo mkdir -p /mnt/data/dtr

if [ -n "${var.dtr_storage_host}" ]; then
  sudo mount -t nfs ${var.dtr_storage_host}:${var.dtr_storage_path} /mnt/data/dtr
fi

sudo docker run -d -p ${local.minio_port}:${local.minio_port} --name minio --restart unless-stopped \
  -e "MINIO_ACCESS_KEY=${random_string.minio_access_key.result}" \
  -e "MINIO_SECRET_KEY=${random_string.minio_secret_key.result}" \
  -e "MINIO_BROWSER=off" \
  -e "MINIO_REGION=none" \
  -v /mnt/data:/data \
  -v /mnt/config:/root/.minio \
  minio/minio server /data
EOT
    ]
  }
}
