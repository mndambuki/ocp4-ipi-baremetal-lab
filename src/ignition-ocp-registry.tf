data "template_file" "ocp_registry_ignition" {
  template = file(format("%s/ignition/ocp-registry/ignition.yml.tpl", path.module))

  vars = {
    fqdn                     = local.ocp_registry.fqdn
    ssh_pubkey               = trimspace(tls_private_key.ssh_maintuser.public_key_openssh)
    registry_version         = var.ocp_registry.version
    registry_htpasswd        = format("%s:%s", var.ocp_registry.username, bcrypt(var.ocp_registry.password))
    registry_tls_certificate = indent(10, local.ocp_registry_tls.certificate)
    registry_tls_private_key = indent(10, local.ocp_registry_tls.private_key)
  }
}

data "ct_config" "ocp_registry_ignition" {
  content      = data.template_file.ocp_registry_ignition.rendered
  strict       = true
  pretty_print = true
}

resource "local_file" "ocp_registry_ignition_rendered" {

  count = var.DEBUG ? 1 : 0

  filename             = format("output/ignition/ocp-registry.json")
  content              = data.ct_config.ocp_registry_ignition.rendered
  file_permission      = "0600"
  directory_permission = "0700"

  lifecycle {
    ignore_changes = [
      content
    ]
  }
}
