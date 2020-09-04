resource "libvirt_network" "ocp_provisioning" {
  name      = var.network_provisioning.name
  mode      = "none"
  bridge    = var.network_provisioning.bridge
  mtu       = 1500
  addresses = [ var.network_provisioning.subnet ]
  autostart = true

  dhcp {
    enabled = false
  }

  dns {
    enabled = false
  }
}
