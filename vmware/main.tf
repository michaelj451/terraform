terraform {
  required_version = ">= 1.6.0"
  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "~> 2.6"
    }
  }
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

# Lookups
data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_host" "esxi" {
  name          = var.esxi_host
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "ds" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "net" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "tmpl" {
  name          = var.template
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Create many VMs from the list
resource "vsphere_virtual_machine" "vm" {
  for_each = { for vm in var.vms : vm.name => vm }

  name             = each.value.name
  resource_pool_id = data.vsphere_host.esxi.resource_pool_id
  datastore_id     = data.vsphere_datastore.ds.id

  # Compute (use template defaults; tweak if desired)
  num_cpus = 4
  memory   = 8192
  # If you enabled per-VM overrides in variables.tf, use:
  # num_cpus = try(each.value.cpu, 4)
  # memory   = try(each.value.memory, 8192)

  guest_id  = data.vsphere_virtual_machine.tmpl.guest_id
  scsi_type = data.vsphere_virtual_machine.tmpl.scsi_type

  # Don’t block on IP during creation; useful while testing
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
        host_name = each.value.name
        domain    = var.domain
      }

      # Static IP for each VM from the list
      network_interface {
        ipv4_address = each.value.ip
        ipv4_netmask = var.netmask_bits
      }

      ipv4_gateway    = var.gateway
      dns_server_list = var.dns_servers
      dns_suffix_list = [var.domain]
    }
  }
}

# Helpful outputs
output "vm_ids" {
  value = { for k, v in vsphere_virtual_machine.vm : k => v.id }
}

output "vm_ips" {
  value = { for k, v in vsphere_virtual_machine.vm : k => v.default_ip_address }
}