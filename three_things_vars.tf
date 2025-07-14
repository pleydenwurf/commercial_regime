# terraform/variables.tf
variable "vsphere_user" {
  description = "vSphere username"
  type        = string
  sensitive   = true
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "vSphere server"
  type        = string
}

variable "datacenter" {
  description = "vSphere datacenter"
  type        = string
}

variable "datastore" {
  description = "vSphere datastore"
  type        = string
}

variable "cluster" {
  description = "vSphere cluster"
  type        = string
}

variable "network" {
  description = "vSphere network"
  type        = string
}

variable "template_name" {
  description = "Rocky Linux 9.6 template name"
  type        = string
}

variable "vm_folder" {
  description = "vSphere folder for VMs"
  type        = string
  default     = ""
}

variable "domain" {
  description = "Domain name"
  type        = string
  default     = "local.lab"
}

variable "traefik_ip" {
  description = "Static IP for Traefik server"
  type        = string
}

variable "nginx_ip" {
  description = "Static IP for Nginx server"
  type        = string
}

variable "stepca_ip" {
  description = "Static IP for Step CA server"
  type        = string
}

variable "netmask" {
  description = "Network netmask"
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Network gateway"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "artifactory_url" {
  description = "Local Artifactory URL"
  type        = string
}
