resource "random_password" "ipmi_worker" {
  count   = var.ocp_cluster.num_workers
  length  = 16
  special = false
}

locals {
  ocp_worker = [
    for index in range(var.ocp_cluster.num_workers) :
      {
        id       = format("ocp-worker%02d", index)
        hostname = format("worker%02d", index)
        fqdn     = format("worker%02d.%s", index, var.dns.domain)
        network_baremetal = {
          ip  = lookup(var.ocp_inventory, format("worker%02d", index)).network_baremetal.ip
          mac = lookup(var.ocp_inventory, format("worker%02d", index)).network_baremetal.mac
        }
        network_provisioning = {
          ip  = lookup(var.ocp_inventory, format("worker%02d", index)).network_provisioning.ip
          mac = lookup(var.ocp_inventory, format("worker%02d", index)).network_provisioning.mac
        }
        ipmi = {
          ip   = var.network_baremetal.gateway
          port = tostring(6240 + index)
          user = var.ipmi.username
          pass = random_password.ipmi_worker[index].result
        }
      }
  ]
}

resource "libvirt_volume" "ocp_worker" {

  count = var.ocp_cluster.num_workers

  name   = format("%s-volume.qcow2", local.ocp_worker[count.index].hostname)
  pool   = libvirt_pool.openshift.name
  size   = var.ocp_worker.size * pow(10, 9) # Bytes
  format = "qcow2"
}

resource "libvirt_domain" "ocp_worker" {

  count = var.ocp_cluster.num_workers

  name    = local.ocp_worker[count.index].id
  vcpu    = var.ocp_worker.vcpu
  memory  = var.ocp_worker.memory
  running = false

  disk {
    volume_id = libvirt_volume.ocp_worker.*.id[count.index]
    scsi      = true
  }

  network_interface {
    network_name = libvirt_network.ocp_provisioning.name
    mac          = local.ocp_worker[count.index].network_provisioning.mac
  }

  network_interface {
    network_name = libvirt_network.ocp_baremetal.name
    mac          = local.ocp_worker[count.index].network_baremetal.mac
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
