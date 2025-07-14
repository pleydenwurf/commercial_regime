# terraform/main.tf
terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.4"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.2"
    }
  }
  required_version = ">= 1.0"
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = var.allow_unverified_ssl
}

provider "dns" {
  update {
    server = var.dns_server
  }
}

# Data sources
data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
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

# Resource pool for our three VMs
resource "vsphere_resource_pool" "proxy_infrastructure" {
  name                    = "proxy-infrastructure"
  parent_resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  cpu_share_level         = "normal"
  memory_share_level      = "normal"
}

# VM 1: Traefik Server (Docker-based)
resource "vsphere_virtual_machine" "traefik" {
  name                 = "${var.vm_prefix}-traefik"
  resource_pool_id     = vsphere_resource_pool.proxy_infrastructure.id
  datastore_id         = data.vsphere_datastore.datastore.id
  num_cpus             = var.traefik_vm.cpu
  memory               = var.traefik_vm.memory
  guest_id             = data.vsphere_virtual_machine.template.guest_id
  scsi_type            = data.vsphere_virtual_machine.template.scsi_type
  firmware             = data.vsphere_virtual_machine.template.firmware
  wait_for_guest_net_timeout = 5
  wait_for_guest_ip_timeout  = 5

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = var.traefik_vm.disk
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "${var.vm_prefix}-traefik"
        domain    = var.domain
      }

      network_interface {
        ipv4_address = var.traefik_vm.ip_address
        ipv4_netmask = var.vm_netmask
      }

      ipv4_gateway    = var.vm_gateway
      dns_server_list = var.dns_servers
    }
  }

  extra_config = {
    "guestinfo.userdata" = base64encode(templatefile("${path.module}/cloud-init-traefik.yaml", {
      ssh_public_key = var.ssh_public_key
      hostname       = "${var.vm_prefix}-traefik"
      domain         = var.domain
      artifactory_url = var.artifactory_url
    }))
    "guestinfo.userdata.encoding" = "base64"
  }

  tags = [
    vsphere_tag.environment.id,
    vsphere_tag.traefik_app.id,
    vsphere_tag.owner.id
  ]
}

# VM 2: Nginx Reverse Proxy
resource "vsphere_virtual_machine" "nginx" {
  name                 = "${var.vm_prefix}-nginx"
  resource_pool_id     = vsphere_resource_pool.proxy_infrastructure.id
  datastore_id         = data.vsphere_datastore.datastore.id
  num_cpus             = var.nginx_vm.cpu
  memory               = var.nginx_vm.memory
  guest_id             = data.vsphere_virtual_machine.template.guest_id
  scsi_type            = data.vsphere_virtual_machine.template.scsi_type
  firmware             = data.vsphere_virtual_machine.template.firmware
  wait_for_guest_net_timeout = 5
  wait_for_guest_ip_timeout  = 5

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = var.nginx_vm.disk
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "${var.vm_prefix}-nginx"
        domain    = var.domain
      }

      network_interface {
        ipv4_address = var.nginx_vm.ip_address
        ipv4_netmask = var.vm_netmask
      }

      ipv4_gateway    = var.vm_gateway
      dns_server_list = var.dns_servers
    }
  }

  extra_config = {
    "guestinfo.userdata" = base64encode(templatefile("${path.module}/cloud-init-nginx.yaml", {
      ssh_public_key = var.ssh_public_key
      hostname       = "${var.vm_prefix}-nginx"
      domain         = var.domain
      artifactory_url = var.artifactory_url
    }))
    "guestinfo.userdata.encoding" = "base64"
  }

  tags = [
    vsphere_tag.environment.id,
    vsphere_tag.nginx_app.id,
    vsphere_tag.owner.id
  ]
}

# VM 3: Step CA ACME Server
resource "vsphere_virtual_machine" "step_ca" {
  name                 = "${var.vm_prefix}-step-ca"
  resource_pool_id     = vsphere_resource_pool.proxy_infrastructure.id
  datastore_id         = data.vsphere_datastore.datastore.id
  num_cpus             = var.step_ca_vm.cpu
  memory               = var.step_ca_vm.memory
  guest_id             = data.vsphere_virtual_machine.template.guest_id
  scsi_type            = data.vsphere_virtual_machine.template.scsi_type
  firmware             = data.vsphere_virtual_machine.template.firmware
  wait_for_guest_net_timeout = 5
  wait_for_guest_ip_timeout  = 5

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = var.step_ca_vm.disk
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "${var.vm_prefix}-step-ca"
        domain    = var.domain
      }

      network_interface {
        ipv4_address = var.step_ca_vm.ip_address
        ipv4_netmask = var.vm_netmask
      }

      ipv4_gateway    = var.vm_gateway
      dns_server_list = var.dns_servers
    }
  }

  extra_config = {
    "guestinfo.userdata" = base64encode(templatefile("${path.module}/cloud-init-step-ca.yaml", {
      ssh_public_key = var.ssh_public_key
      hostname       = "${var.vm_prefix}-step-ca"
      domain         = var.domain
      artifactory_url = var.artifactory_url
    }))
    "guestinfo.userdata.encoding" = "base64"
  }

  tags = [
    vsphere_tag.environment.id,
    vsphere_tag.step_ca_app.id,
    vsphere_tag.owner.id
  ]
}

# DNS Records for internal resolution
resource "dns_a_record_set" "traefik" {
  zone = "${var.domain}."
  name = "traefik"
  addresses = [vsphere_virtual_machine.traefik.default_ip_address]
  ttl = 300
}

resource "dns_a_record_set" "nginx" {
  zone = "${var.domain}."
  name = "nginx"
  addresses = [vsphere_virtual_machine.nginx.default_ip_address]
  ttl = 300
}

resource "dns_a_record_set" "step_ca" {
  zone = "${var.domain}."
  name = "ca"
  addresses = [vsphere_virtual_machine.step_ca.default_ip_address]
  ttl = 300
}

# Service discovery records
resource "dns_a_record_set" "api" {
  zone = "${var.domain}."
  name = "api"
  addresses = [vsphere_virtual_machine.traefik.default_ip_address]
  ttl = 300
}

resource "dns_a_record_set" "app" {
  zone = "${var.domain}."
  name = "app"
  addresses = [vsphere_virtual_machine.nginx.default_ip_address]
  ttl = 300
}

# vSphere Tags
resource "vsphere_tag_category" "environment" {
  name            = "environment"
  cardinality     = "SINGLE"
  description     = "Environment category"
  associable_types = ["VirtualMachine"]
}

resource "vsphere_tag" "environment" {
  name        = var.environment
  category_id = vsphere_tag_category.environment.id
  description = "Environment: ${var.environment}"
}

resource "vsphere_tag_category" "application" {
  name            = "application"
  cardinality     = "SINGLE"
  description     = "Application category"
  associable_types = ["VirtualMachine"]
}

resource "vsphere_tag" "traefik_app" {
  name        = "traefik"
  category_id = vsphere_tag_category.application.id
  description = "Traefik reverse proxy"
}

resource "vsphere_tag" "nginx_app" {
  name        = "nginx"
  category_id = vsphere_tag_category.application.id
  description = "Nginx reverse proxy"
}

resource "vsphere_tag" "step_ca_app" {
  name        = "step-ca"
  category_id = vsphere_tag_category.application.id
  description = "Step CA ACME server"
}

resource "vsphere_tag_category" "owner" {
  name            = "owner"
  cardinality     = "SINGLE"
  description     = "Owner category"
  associable_types = ["VirtualMachine"]
}

resource "vsphere_tag" "owner" {
  name        = var.owner
  category_id = vsphere_tag_category.owner.id
  description = "Owner: ${var.owner}"
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    traefik_ip = vsphere_virtual_machine.traefik.default_ip_address
    nginx_ip   = vsphere_virtual_machine.nginx.default_ip_address
    step_ca_ip = vsphere_virtual_machine.step_ca.default_ip_address
    domain     = var.domain
    artifactory_url = var.artifactory_url
  })
  filename = "${path.module}/../ansible/inventory.yml"
}

# Generate host entries for offline resolution
resource "local_file" "hosts_file" {
  content = templatefile("${path.module}/hosts.tpl", {
    traefik_ip = vsphere_virtual_machine.traefik.default_ip_address
    nginx_ip   = vsphere_virtual_machine.nginx.default_ip_address
    step_ca_ip = vsphere_virtual_machine.step_ca.default_ip_address
    domain     = var.domain
    artifactory_url = var.artifactory_url
    artifactory_ip = var.artifactory_ip
  })
  filename = "${path.module}/../ansible/files/hosts"
}

# Run Ansible after VM creation
resource "null_resource" "run_ansible" {
  depends_on = [
    vsphere_virtual_machine.traefik,
    vsphere_virtual_machine.nginx,
    vsphere_virtual_machine.step_ca,
    local_file.ansible_inventory,
    local_file.hosts_file
  ]

  provisioner "local-exec" {
    command = <<-EOT
      sleep 60  # Wait for VMs to fully boot
      cd ../ansible
      ansible-playbook -i inventory.yml site.yml
    EOT
  }

  triggers = {
    traefik_ip = vsphere_virtual_machine.traefik.default_ip_address
    nginx_ip   = vsphere_virtual_machine.nginx.default_ip_address
    step_ca_ip = vsphere_virtual_machine.step_ca.default_ip_address
  }
}

# Outputs
output "traefik_ip" {
  value = vsphere_virtual_machine.traefik.default_ip_address
}

output "nginx_ip" {
  value = vsphere_virtual_machine.nginx.default_ip_address
}

output "step_ca_ip" {
  value = vsphere_virtual_machine.step_ca.default_ip_address
}

output "traefik_dashboard" {
  value = "https://traefik.${var.domain}:8080"
}

output "nginx_status" {
  value = "http://nginx.${var.domain}/status"
}

output "step_ca_health" {
  value = "https://ca.${var.domain}:9000/health"
}

output "ssh_commands" {
  value = {
    traefik = "ssh -i ${var.ssh_private_key_path} root@${vsphere_virtual_machine.traefik.default_ip_address}"
    nginx   = "ssh -i ${var.ssh_private_key_path} root@${vsphere_virtual_machine.nginx.default_ip_address}"
    step_ca = "ssh -i ${var.ssh_private_key_path} root@${vsphere_virtual_machine.step_ca.default_ip_address}"
  }
}
