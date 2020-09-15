resource "libvirt_volume" "ocp_node" {
  name   = format("%s-volume.qcow2", var.hostname)
  pool   = var.libvirt_pool
  size   = var.disk_size * pow(10, 9) # Bytes
  format = "qcow2"
}
