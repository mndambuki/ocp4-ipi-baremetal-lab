resource "libvirt_domain" "ocp_node" {
  name    = format("ocp-%s", var.hostname)
  vcpu    = var.cpu
  memory  = var.memory
  running = false

  # UEFI
  machine  = "q35"
  firmware = "/usr/share/OVMF/OVMF_CODE.secboot.fd"
  nvram {
    file = format("/var/lib/libvirt/qemu/nvram/ocp-%s-vars.fd", var.hostname)
  }

  disk {
    volume_id = libvirt_volume.ocp_node.id
    scsi      = true
  }

  network_interface {
    network_name = var.network_provisioning_name
    mac          = var.network_provisioning_mac
  }

  network_interface {
    network_name = var.network_baremetal_name
    mac          = var.network_baremetal_mac
  }

  console {
    type           = "pty"
    target_type    = "serial"
    target_port    = "0"
    source_host    = "127.0.0.1"
    source_service = "0"
  }

  boot_device {
    dev = [ "network" ]
  }

  # Enable boot console
  xml {
    xslt = <<EOL
      <?xml version="1.0" ?>
      <xsl:stylesheet version="1.0"
          xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

          <!-- Identity template -->
          <xsl:template match="@* | node()">
              <xsl:copy>
                  <xsl:apply-templates select="@* | node()"/>
              </xsl:copy>
          </xsl:template>

          <!-- Override for target element -->
          <xsl:template match="os">
              <xsl:copy>
                  <xsl:apply-templates select="@* | node()"/>
                  <bios useserial="yes"/>
              </xsl:copy>
          </xsl:template>

      </xsl:stylesheet>
    EOL
  }

  lifecycle {
    ignore_changes = [
      running
    ]
  }

}
