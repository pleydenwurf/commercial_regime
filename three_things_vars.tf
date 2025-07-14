# terraform/variables.tf
variable "vsphere_server" {
  description = "vSphere server hostname or IP"
  type        = string
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "allow_unverified_ssl" {
  description = "Allow unverified SSL certificates"
  type        = bool
  default     = true
}

variable "datacenter" {
  description = "vSphere datacenter name"
  type        = string
}

variable "cluster" {
  description = "vSphere cluster name"
  type        = string
}

variable "datastore" {
  description = "vSphere datastore name"
  type        = string
}

variable "network" {
  description = "vSphere network name"
  type        = string
}

variable "template_name" {
  description = "VM template name"
  type        = string
  default     = "rocky-linux-9.6-template"
}

variable "vm_prefix" {
  description = "Prefix for VM names"
  type        = string
  default     = "proxy"
}

variable "vm_netmask" {
  description = "Network mask for VMs"
  type        = number
  default     = 24
}

variable "vm_gateway" {
  description = "Gateway IP address"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers list"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "dns_server" {
  description = "DNS server for record management"
  type        = string
}

variable "domain" {
  description = "Domain name for services"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "admin"
}

variable "artifactory_url" {
  description = "Local Artifactory URL"
  type        = string
}

variable "artifactory_ip" {
  description = "Local Artifactory IP address"
  type        = string
}

# Traefik VM Configuration
variable "traefik_vm" {
  description = "Traefik VM configuration"
  type = object({
    cpu        = number
    memory     = number
    disk       = number
    ip_address = string
  })
  default = {
    cpu        = 2
    memory     = 4096
    disk       = 40
    ip_address = "192.168.1.10"
  }
}

# Nginx VM Configuration
variable "nginx_vm" {
  description = "Nginx VM configuration"
  type = object({
    cpu        = number
    memory     = number
    disk       = number
    ip_address = string
  })
  default = {
    cpu        = 2
    memory     = 2048
    disk       = 30
    ip_address = "192.168.1.11"
  }
}

# Step CA VM Configuration
variable "step_ca_vm" {
  description = "Step CA VM configuration"
  type = object({
    cpu        = number
    memory     = number
    disk       = number
    ip_address = string
  })
  default = {
    cpu        = 1
    memory     = 2048
    disk       = 30
    ip_address = "192.168.1.12"
  }
}

---
# terraform/cloud-init-traefik.yaml
#cloud-config
hostname: ${hostname}
fqdn: ${hostname}.${domain}

users:
  - name: root
    ssh_authorized_keys:
      - ${ssh_public_key}
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL

package_update: false
package_upgrade: false

write_files:
  - path: /etc/yum.repos.d/artifactory.repo
    content: |
      [artifactory]
      name=Local Artifactory
      baseurl=${artifactory_url}/artifactory/rocky-linux-9/
      enabled=1
      gpgcheck=0
      
  - path: /etc/docker/daemon.json
    content: |
      {
        "insecure-registries": ["${artifactory_url}:8082"],
        "registry-mirrors": ["${artifactory_url}:8082"]
      }

runcmd:
  - echo "Setting up Traefik VM..." > /var/log/cloud-init-custom.log
  - systemctl disable --now NetworkManager
  - systemctl enable --now network
  - echo "Traefik VM setup complete" >> /var/log/cloud-init-custom.log

final_message: "Traefik VM ready for Ansible configuration."

---
# terraform/cloud-init-nginx.yaml
#cloud-config
hostname: ${hostname}
fqdn: ${hostname}.${domain}

users:
  - name: root
    ssh_authorized_keys:
      - ${ssh_public_key}
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL

package_update: false
package_upgrade: false

write_files:
  - path: /etc/yum.repos.d/artifactory.repo
    content: |
      [artifactory]
      name=Local Artifactory
      baseurl=${artifactory_url}/artifactory/rocky-linux-9/
      enabled=1
      gpgcheck=0

runcmd:
  - echo "Setting up Nginx VM..." > /var/log/cloud-init-custom.log
  - systemctl disable --now NetworkManager
  - systemctl enable --now network
  - echo "Nginx VM setup complete" >> /var/log/cloud-init-custom.log

final_message: "Nginx VM ready for Ansible configuration."

---
# terraform/cloud-init-step-ca.yaml
#cloud-config
hostname: ${hostname}
fqdn: ${hostname}.${domain}

users:
  - name: root
    ssh_authorized_keys:
      - ${ssh_public_key}
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL

package_update: false
package_upgrade: false

write_files:
  - path: /etc/yum.repos.d/artifactory.repo
    content: |
      [artifactory]
      name=Local Artifactory
      baseurl=${artifactory_url}/artifactory/rocky-linux-9/
      baseurl=${artifactory_url}/artifactory/step-ca-repo/
      enabled=1
      gpgcheck=0

runcmd:
  - echo "Setting up Step CA VM..." > /var/log/cloud-init-custom.log
  - systemctl disable --now NetworkManager
  - systemctl enable --now network
  - echo "Step CA VM setup complete" >> /var/log/cloud-init-custom.log

final_message: "Step CA VM ready for Ansible configuration."

---
# terraform/inventory.tpl
all:
  children:
    traefik_servers:
      hosts:
        traefik:
          ansible_host: ${traefik_ip}
          ansible_user: root
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
          vm_role: traefik
          
    nginx_servers:
      hosts:
        nginx:
          ansible_host: ${nginx_ip}
          ansible_user: root
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
          vm_role: nginx
          
    step_ca_servers:
      hosts:
        step-ca:
          ansible_host: ${step_ca_ip}
          ansible_user: root
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
          vm_role: step_ca
          
  vars:
    domain: ${domain}
    artifactory_url: ${artifactory_url}
    traefik_ip: ${traefik_ip}
    nginx_ip: ${nginx_ip}
    step_ca_ip: ${step_ca_ip}
    
---
# terraform/hosts.tpl
# Generated hosts file for offline deployment
127.0.0.1   localhost localhost.localdomain
${traefik_ip}   traefik.${domain} traefik
${nginx_ip}     nginx.${domain} nginx app.${domain}
${step_ca_ip}   ca.${domain} step-ca
${artifactory_ip}   artifactory.${domain} artifactory

# Service discovery
${traefik_ip}   api.${domain}
${nginx_ip}     www.${domain}

---
# terraform/terraform.tfvars.example
# vSphere Configuration
vsphere_server = "vcenter.example.com"
vsphere_user   = "administrator@vsphere.local"
# vsphere_password = "set_via_env_var"

# Infrastructure
datacenter = "Datacenter1"
cluster    = "Cluster1"
datastore  = "datastore1"
network    = "VM Network"

# VM Configuration
vm_prefix  = "proxy"
vm_gateway = "192.168.1.1"
dns_servers = ["192.168.1.1"]
dns_server = "192.168.1.1"

# Domain and Artifactory
domain = "internal.local"
artifactory_url = "http://artifactory.internal.local:8081"
artifactory_ip = "192.168.1.5"

# SSH Configuration
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC..."

# VM Specifications
traefik_vm = {
  cpu        = 2
  memory     = 4096
  disk       = 40
  ip_address = "192.168.1.10"
}

nginx_vm = {
  cpu        = 2
  memory     = 2048
  disk       = 30
  ip_address = "192.168.1.11"
}

step_ca_vm = {
  cpu        = 1
  memory     = 2048
  disk       = 30
  ip_address = "192.168.1.12"
}

# Environment
environment = "production"
owner      = "ops-team"
