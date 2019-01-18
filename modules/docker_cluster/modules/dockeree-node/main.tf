locals {
  hostname_prefix = "dockeree-${var.environment}-${var.node_type}"
}

data "template_file" "swarm_init" {
  template = "${file("${path.module}/scripts/swarm_init.tpl.sh")}"

  vars {
    environment         = "${var.environment}"
    consul_secret       = "${var.consul_secret}"
    ucp_admin_username  = "${var.ucp_admin_username}"
    ucp_admin_password  = "${var.ucp_admin_password}"
    ucp_dns_name        = "${var.ucp_dns_name}"
    dtr_dns_name        = "${var.dtr_dns_name}"
    manager_zero_ip     = "${var.primary_manager_ip}"
    ucp_version         = "${var.ucp_version}"
  }
}

data "template_file" "docker_util" {
  template = "${file("${path.module}/scripts/docker_util.tpl.sh")}"

  vars {
    environment         = "${var.environment}"
    consul_secret       = "${var.consul_secret}"
    ucp_admin_username  = "${var.ucp_admin_username}"
    ucp_admin_password  = "${var.ucp_admin_password}"
    ucp_dns_name        = "${var.ucp_dns_name}"
    dtr_dns_name        = "${var.dtr_dns_name}"
    manager_zero_ip     = "${var.primary_manager_ip}"
    ucp_version         = "${var.ucp_version}"
  }
}

data "template_file" "config_dtr_minio" {
  template = "${file("${path.module}/scripts/config_dtr_minio.tpl.py")}"

  vars {
    ucp_admin_username  = "${var.ucp_admin_username}"
    ucp_admin_password  = "${var.ucp_admin_password}"
    minio_endpoint      = "${var.minio_endpoint}"
    minio_access_key    = "${var.minio_access_key}"
    minio_secret_key    = "${var.minio_secret_key}"
  }
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

data "vsphere_virtual_machine" "template" {
  name          = "${var.vm_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "dockeree" {
  count                   = "${var.node_count}"

  name               = "${local.hostname_prefix}-${var.start_id + count.index}"
  folder             = "${var.vsphere_folder}"
  resource_pool_id   = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id       = "${data.vsphere_datastore.datastore.id}"

  num_cpus   = "${var.node_vcpu}"
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
          host_name = "${local.hostname_prefix}-${var.start_id + count.index}"
          domain    = "${var.domain}"
        }
        network_interface {}
        dns_server_list = ["8.8.8.8"]
        dns_suffix_list = ["${var.domain}"]
    }
  }

  provisioner "file" {
    connection = {
      type          = "ssh"
      user          = "${var.ssh_username}"
      password      = "${var.ssh_password}"
    }

    content     = "${data.template_file.swarm_init.rendered}"
    destination = "/tmp/swarm_init.sh"
  }

  provisioner "file" {
    connection = {
      type          = "ssh"
      user          = "${var.ssh_username}"
      password      = "${var.ssh_password}"
    }

    content     = "${data.template_file.docker_util.rendered}"
    destination = "/tmp/docker_util.sh"
  }

  provisioner "file" {
    connection = {
      type          = "ssh"
      user          = "${var.ssh_username}"
      password      = "${var.ssh_password}"
  }

  source     = "${path.module}/scripts/utils"
  destination = "/tmp/"
  }

  provisioner "file" {
    connection = {
      type     = "ssh"
      user     = "${var.ssh_username}"
      password = "${var.ssh_password}"
    }

    content     = "${data.template_file.config_dtr_minio.rendered}"
    destination = "/tmp/config_dtr_minio.sh"
  }

  provisioner "remote-exec" {
    connection = {
      type     = "ssh"
      user     = "${var.ssh_username}"
      password = "${var.ssh_password}"
    }

    inline = [
      <<EOT
echo "${var.node_count}" > /tmp/node_count
chmod +x /tmp/swarm_init.sh /tmp/config_dtr_minio.sh
sudo /tmp/swarm_init.sh | tee /tmp/swarm_init.log
EOT
    ]
  }

}
