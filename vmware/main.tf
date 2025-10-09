terraform {
  required_version = ">= 1.6.0"
  required_providers {
    vsphere = {
      source  = "vmware/vsphere" # updated source
      version = "~> 2.6"
    }
  }
}

# -----------------------------
# Provider (vCenter)
# -----------------------------
provider "vsphere" {
  user                 = "mxferguson@mxferguson.com"
  password             = "Xm3nbl00d"
  vsphere_server       = "vcenter8.mxferguson.com"
  allow_unverified_ssl = true
}

# -----------------------------
# Inventory lookups
# -----------------------------
data "vsphere_datacenter" "dc" {
  name = "lab"
}

data "vsphere_host" "esxi" {
  name          = "vsphere1.mxferguson.com"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "ds" {
  name          = "iscsi-disk-4.1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "net" {
  name          = "DPortGroup-250"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "tmpl" {
  name          = "ubuntu22-docker-template"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# -----------------------------
# Virtual Machine
# -----------------------------
resource "vsphere_virtual_machine" "vm" {
  name             = "ubuntu22-test-tf-1"                    # REQUIRED
  resource_pool_id = data.vsphere_host.esxi.resource_pool_id # REQUIRED
  datastore_id     = data.vsphere_datastore.ds.id            # REQUIRED

  num_cpus  = 4
  memory    = 8192
  guest_id  = data.vsphere_virtual_machine.tmpl.guest_id
  scsi_type = data.vsphere_virtual_machine.tmpl.scsi_type

  # Don’t block on IP while debugging
  wait_for_guest_ip_timeout   = 0
  wait_for_guest_net_timeout  = 0
  wait_for_guest_net_routable = false

  network_interface {
    network_id   = data.vsphere_network.net.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.tmpl.disks.0.size
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.tmpl.id
    customize {
      linux_options {
        host_name = "ubuntu22-test-1"
        domain    = "mxferguson.com"
      }

      # Static IPv4
      network_interface {
        ipv4_address = "10.4.5.101" # choose a free IP
        ipv4_netmask = 24
      }

      ipv4_gateway    = "10.4.5.1"
      dns_server_list = ["10.3.0.151", "10.3.0.152"]
      dns_suffix_list = ["mxferguson.com"]
    }
  }
}

# -----------------------------
# Outputs
# -----------------------------
output "vm_name" { value = vsphere_virtual_machine.vm.name }
output "vm_power_state" { value = vsphere_virtual_machine.vm.power_state }