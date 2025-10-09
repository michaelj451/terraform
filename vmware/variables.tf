variable "vsphere_user" {
  type = string
}

variable "vsphere_password" {
  type      = string
  sensitive = true
}

variable "vsphere_server" {
  type = string
}

variable "datacenter" {
  type = string
}

variable "esxi_host" {
  type = string
}

variable "datastore" {
  type = string
}

variable "network" {
  type = string
}

variable "template" {
  type = string
}

variable "domain" {
  type    = string
  default = "mxferguson.com"
}

variable "dns_servers" {
  type    = list(string)
  default = ["10.3.0.151", "10.3.0.152"]
}

variable "gateway" {
  type = string
}

variable "netmask_bits" {
  type = number
}

variable "vms" {
  description = "VMs to create"
  type = list(object({
    name = string
    ip   = string
    # Uncomment if you want per-VM overrides:
    # cpu    = optional(number, 4)
    # memory = optional(number, 8192)
  }))
}