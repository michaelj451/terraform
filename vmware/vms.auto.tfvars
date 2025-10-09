# -----------------------------
# vCenter connection
# -----------------------------
vsphere_user     = "mxferguson@mxferguson.com"
vsphere_password = "Xm3nbl00d"
vsphere_server   = "vcenter8.mxferguson.com"

# -----------------------------
# vSphere inventory
# -----------------------------
datacenter = "lab"
esxi_host  = "vsphere1.mxferguson.com"
datastore  = "iscsi-disk-4.1"
network    = "DPortGroup-250"
template   = "ubuntu22-docker-template"

# -----------------------------
# Network defaults
# -----------------------------
gateway      = "10.4.5.1"
netmask_bits = 24
dns_servers  = ["10.3.0.151", "10.3.0.152"]
domain       = "mxferguson.com"

# -----------------------------
# VM definitions
# -----------------------------
vms = [
  { name = "ubuntu22-test-1", ip = "10.4.5.101" },
  { name = "ubuntu22-test-2", ip = "10.4.5.102" },
  { name = "ubuntu22-test-3", ip = "10.4.5.103" }
]