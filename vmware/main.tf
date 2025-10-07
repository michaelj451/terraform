terraform {
  required_version = ">= 1.6.0"
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
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

# No cluster: point to the ESXi host and use its default resource pool
data "vsphere_host" "esxi" {
  name          = "vsphere4.mxferguson.com"   # <-- change if your ESXi host name differs
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "ds" {
  name          = "iscsi-disk-4.1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Must match the portgroup's exact name
data "vsphere_network" "net" {
  name          = "DPortGroup-250"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Ubuntu TEMPLATE (not just a powered-off VM)
data "vsphere_virtual_machine" "tmpl" {
  name          = "ubuntu22-docker-template"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# -----------------------------
# Virtual Machine
# -----------------------------
resource "vsphere_virtual_machine" "vm" {
  name             = "vsphere1"  # VM display name; FQDN will be vsphere1.mxferguson.com via customization
  resource_pool_id = data.vsphere_host.esxi.resource_pool_id
  datastore_id     = data.vsphere_datastore.ds.id

  # Compute
  num_cpus = 4
  memory   = 8192  # MB (8 GB)

  # Guest & hardware from template
  guest_id  = data.vsphere_virtual_machine.tmpl.guest_id
  scsi_type = data.vsphere_virtual_machine.tmpl.scsi_type

  # Networking
  network_interface {
    network_id   = data.vsphere_network.net.id
    adapter_type = data.vsphere_virtual_machine.tmpl.network_interface_types[0]
  }

  # Disk (inherits size from template; adjust size if you want larger)
  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.tmpl.disks.0.size
    eagerly_scrub    = false
    thin_provisioned = true
  }

  # Clone from template with guest customization (DHCP)
  clone {
    template_uuid = data.vsphere_virtual_machine.tmpl.id

    customize {
      linux_options {
        host_name = "vsphere1"
        domain    = "mxferguson.com"
      }
      # DHCP networking
      dns_server_list = ["10.3.0.151", "10.3.0.152"]
      ipv4_gateway    = null
    }
  }
}

# -----------------------------
# Outputs
# -----------------------------
output "vm_name"        { value = vsphere_virtual_machine.vm.name }
output "vm_power_state" { value = vsphere_virtual_machine.vm.power_state }