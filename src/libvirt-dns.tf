data "template_file" "dnsmasq_conf_ocp" {

  template = file(format("%s/dns/dnsmasq_server.conf", path.module))

  vars = {
    dns_zone   = var.dns.domain
    dns_server = var.dns.server
  }
}

resource "local_file" "nm_enable_dnsmasq" {
  filename             = "/etc/NetworkManager/conf.d/enable_dnsmasq.conf"
  content              = file(format("%s/dns/nm_enable_dnsmasq.conf", path.module))
  file_permission      = "0666"
  directory_permission = "0755"
}

resource "local_file" "dnsmasq_conf_ocp" {
  filename             = "/etc/NetworkManager/dnsmasq.d/openshift-metal3.conf"
  content              = data.template_file.dnsmasq_conf_ocp.rendered
  file_permission      = "0666"
  directory_permission = "0755"

  provisioner "local-exec" {
    command = "sudo systemctl restart NetworkManager"
  }

  depends_on = [
    local_file.nm_enable_dnsmasq
  ]
}
