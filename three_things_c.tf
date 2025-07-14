# terraform/main.tf
terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.0"
    }
  }
}

# Configure the VMware vSphere Provider
provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server
  allow_unverified_ssl = true
}

# Data sources
data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Traefik VM
resource "vsphere_virtual_machine" "traefik" {
  name             = "traefik-server"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vm_folder

  num_cpus = 2
  memory   = 4096
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "traefik-server"
        domain    = var.domain
      }

      network_interface {
        ipv4_address = var.traefik_ip
        ipv4_netmask = var.netmask
      }

      ipv4_gateway = var.gateway
      dns_server_list = var.dns_servers
    }
  }

  tags = ["traefik", "rocky-linux"]
}

# Nginx VM
resource "vsphere_virtual_machine" "nginx" {
  name             = "nginx-proxy"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vm_folder

  num_cpus = 2
  memory   = 2048
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "nginx-proxy"
        domain    = var.domain
      }

      network_interface {
        ipv4_address = var.nginx_ip
        ipv4_netmask = var.netmask
      }

      ipv4_gateway = var.gateway
      dns_server_list = var.dns_servers
    }
  }

  tags = ["nginx", "rocky-linux"]
}

# Step CA VM
resource "vsphere_virtual_machine" "stepca" {
  name             = "stepca-server"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vm_folder

  num_cpus = 2
  memory   = 2048
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "stepca-server"
        domain    = var.domain
      }

      network_interface {
        ipv4_address = var.stepca_ip
        ipv4_netmask = var.netmask
      }

      ipv4_gateway = var.gateway
      dns_server_list = var.dns_servers
    }
  }

  tags = ["stepca", "rocky-linux"]
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    traefik_ip = var.traefik_ip
    nginx_ip   = var.nginx_ip
    stepca_ip  = var.stepca_ip
    domain     = var.domain
    artifactory_url = var.artifactory_url
  })
  filename = "../ansible/inventory/hosts.yml"
}

# Output values
output "traefik_ip" {
  value = vsphere_virtual_machine.traefik.default_ip_address
}

output "nginx_ip" {
  value = vsphere_virtual_machine.nginx.default_ip_address
}

output "stepca_ip" {
  value = vsphere_virtual_machine.stepca.default_ip_address
}
