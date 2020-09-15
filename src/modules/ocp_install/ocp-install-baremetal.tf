data "template_file" "install_config_baremetal" {

  count = (var.platform.kind == "baremetal") ? 1 : 0

  template = file(format("%s/templates/install-config-baremetal.yaml.tpl", path.module))

  vars = {
    cluster_name                             = var.cluster_name
    dns_domain                               = var.dns_domain
    nodes_cidr                               = var.nodes_cidr
    pods_cidr                                = var.pods_cidr
    pods_range                               = var.pods_range
    svcs_cidr                                = var.svcs_cidr
    pull_secret                              = var.pull_secret
    ssh_pubkey                               = var.ssh_pubkey
    additional_ca                            = var.additional_ca
    baremetal_api_vip                        = var.platform.baremetal_api_vip
    baremetal_ingress_vip                    = var.platform.baremetal_ingress_vip
    baremetal_network_baremetal_bridge       = var.platform.baremetal_network_baremetal_bridge
    baremetal_network_provisioning_cidr      = var.platform.baremetal_network_provisioning_cidr
    baremetal_network_provisioning_bridge    = var.platform.baremetal_network_provisioning_bridge
    baremetal_network_provisioning_interface = var.platform.baremetal_network_provisioning_interface
    baremetal_network_provisioning_dhcp      = var.platform.baremetal_network_provisioning_dhcp
    baremetal_network_provisioning_range     = var.platform.baremetal_network_provisioning_range
    baremetal_hosts                          = indent(6, join("\n", data.template_file.baremetal_hosts.*.rendered))
  }

}

resource "local_file" "install_config_baremetal" {

  count = (var.platform.kind == "baremetal") ? 1 : 0

  filename             = format("%s/install-config.yaml", var.output_folder)
  content              = data.template_file.install_config_baremetal.0.rendered
  file_permission      = "0644"
  directory_permission = "0755"
}

resource "local_file" "install_config_baremetal_backup" {

  count = (var.platform.kind == "baremetal") ? 1 : 0

  filename             = format("%s/install-config.yaml.backup", var.output_folder)
  content              = data.template_file.install_config_baremetal.0.rendered
  file_permission      = "0644"
  directory_permission = "0755"
}