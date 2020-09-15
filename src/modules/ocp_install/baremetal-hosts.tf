locals {
  number_of_hosts = length(var.platform.baremetal_hosts)
}

data "template_file" "baremetal_hosts" {

  count = (var.platform.kind == "baremetal") ? local.number_of_hosts : 0

  template = file(format("%s/templates/baremetal-host.yaml.tpl", path.module))

  vars = {
    host_name         = var.platform.baremetal_hosts[count.index].name
    host_role         = var.platform.baremetal_hosts[count.index].role
    host_mac          = var.platform.baremetal_hosts[count.index].mac_address
    host_boot_mode    = var.platform.baremetal_hosts[count.index].boot_mode
    host_bmc_address  = format("%s://%s:%s%s",
      var.platform.baremetal_hosts[count.index].bmc.protocol,
      var.platform.baremetal_hosts[count.index].bmc.ip,
      var.platform.baremetal_hosts[count.index].bmc.port,
      var.platform.baremetal_hosts[count.index].bmc.path
    )
    host_bmc_user     = var.platform.baremetal_hosts[count.index].bmc.user
    host_bmc_pass     = var.platform.baremetal_hosts[count.index].bmc.pass
    host_bmc_no_tls   = var.platform.baremetal_hosts[count.index].bmc.no_tls
  }

}
