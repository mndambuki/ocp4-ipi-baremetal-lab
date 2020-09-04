locals {
  ocp_registry = {
    id       = format("ocp-%s", var.ocp_registry.id)
    hostname = var.ocp_registry.id
    fqdn     = format("%s.%s", var.ocp_registry.id, var.dns.domain)
    ip       = lookup(var.ocp_inventory, var.ocp_registry.id).network_baremetal.ip
    mac      = lookup(var.ocp_inventory, var.ocp_registry.id).network_baremetal.mac
  }
  ocp_registry_auth = {
    auths = {
      format("%s:%s", local.ocp_registry.fqdn, var.ocp_registry.port) = {
        auth  = base64encode(format("%s:%s", var.ocp_registry.username, var.ocp_registry.password))
        email = format("auto-generated@%s", var.dns.domain)
      }
    }
  }
  ocp_registry_tls = {
    certificate = format("%s%s",
      tls_locally_signed_cert.ocp_registry.cert_pem,
      tls_self_signed_cert.ocp_root_ca.cert_pem
    )
    private_key = tls_private_key.ocp_registry.private_key_pem
  }
}

resource "libvirt_ignition" "ocp_registry" {
  name    = format("%s.ign", local.ocp_registry.hostname)
  pool    = libvirt_pool.openshift.name
  content = data.ct_config.ocp_registry_ignition.rendered

  lifecycle {
    ignore_changes = [
      content
    ]
  }
}

resource "libvirt_volume" "ocp_registry_image" {
  name   = format("%s-baseimg.qcow2", local.ocp_registry.hostname)
  pool   = libvirt_pool.openshift.name
  source = var.ocp_registry.base_img
  format = "qcow2"
}

resource "libvirt_volume" "ocp_registry" {
  name           = format("%s-volume.qcow2", local.ocp_registry.hostname)
  pool           = libvirt_pool.openshift.name
  base_volume_id = libvirt_volume.ocp_registry_image.id
  format         = "qcow2"
  size           = var.ocp_registry.size * pow(10, 9) # Bytes
}

resource "libvirt_domain" "ocp_registry" {
  name    = local.ocp_registry.id
  vcpu    = var.ocp_registry.vcpu
  memory  = var.ocp_registry.memory
  running = true

  coreos_ignition = libvirt_ignition.ocp_registry.id

  disk {
    volume_id = libvirt_volume.ocp_registry.id
    scsi      = false
  }

  network_interface {
    network_name   = libvirt_network.ocp_baremetal.name
    hostname       = format("%s.%s", local.ocp_registry.hostname, var.dns.domain)
    addresses      = [ local.ocp_registry.ip ]
    mac            = local.ocp_registry.mac
    wait_for_lease = true
  }

  console {
    type           = "pty"
    target_type    = "serial"
    target_port    = "0"
    source_host    = "127.0.0.1"
    source_service = "0"
  }

  lifecycle {
    ignore_changes = [
      running,
      network_interface.0.addresses
    ]
  }

  provisioner "local-exec" {
    when    = destroy
    command = format("ssh-keygen -R %s", self.network_interface.0.hostname)
  }
}
