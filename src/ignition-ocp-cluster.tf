locals {
  ocp_pull_secret_original     = file(format("%s/openshift-install/%s/pull-secret.json", path.module, var.OCP_ENVIRONMENT))
  ocp_pull_secret_disconnected = jsonencode({
    auths = merge(
      jsondecode(local.ocp_pull_secret_original).auths,
      local.ocp_registry_auth.auths
    )
  })
}

data "template_file" "ocp_baremetal_master_hosts" {

  count = var.ocp_cluster.num_masters

  template = file(format("%s/openshift-install/baremetal-host.yaml.tpl", path.module))

  vars = {
    ocp_host_name         = local.ocp_master[count.index].id
    ocp_host_role         = "master"
    ocp_host_bmc_protocol = "ipmi"
    ocp_host_bmc_address  = format("%s:%s", local.ocp_master[count.index].ipmi.ip, local.ocp_master[count.index].ipmi.port)
    ocp_host_bmc_user     = local.ocp_master[count.index].ipmi.user
    ocp_host_bmc_pass     = local.ocp_master[count.index].ipmi.pass
    ocp_host_boot_mode    = "legacy"
    ocp_host_mac          = local.ocp_master[count.index].network_provisioning.mac
  }

}

data "template_file" "ocp_baremetal_worker_hosts" {

  count = var.ocp_cluster.num_workers

  template = file(format("%s/openshift-install/baremetal-host.yaml.tpl", path.module))

  vars = {
    ocp_host_name         = local.ocp_worker[count.index].id
    ocp_host_role         = "worker"
    ocp_host_bmc_protocol = "ipmi"
    ocp_host_bmc_address  = format("%s:%s", local.ocp_worker[count.index].ipmi.ip, local.ocp_worker[count.index].ipmi.port)
    ocp_host_bmc_user     = local.ocp_worker[count.index].ipmi.user
    ocp_host_bmc_pass     = local.ocp_worker[count.index].ipmi.pass
    ocp_host_boot_mode    = "legacy"
    ocp_host_mac          = local.ocp_worker[count.index].network_provisioning.mac
  }

}

data "template_file" "ocp_install_config" {
  template = file(format("%s/openshift-install/install-config.yaml.tpl", path.module))

  vars = {
    ocp_cluster_name                             = var.ocp_cluster.name
    ocp_dns_domain                               = var.ocp_cluster.dns_domain
    ocp_nodes_cidr                               = var.network_baremetal.subnet
    ocp_pods_cidr                                = var.ocp_cluster.pods_cidr
    ocp_pods_range                               = var.ocp_cluster.pods_range
    ocp_svcs_cidr                                = var.ocp_cluster.svcs_cidr
    ocp_baremetal_api_vip                        = var.ocp_cluster.api_vip
    ocp_baremetal_ingress_vip                    = var.ocp_cluster.ingress_vip
    ocp_baremetal_network_baremetal_bridge       = var.network_baremetal.bridge
    ocp_baremetal_network_provisioning_cidr      = var.network_provisioning.subnet
    ocp_baremetal_network_provisioning_bridge    = var.network_provisioning.bridge
    ocp_baremetal_network_provisioning_interface = "ens3"
    ocp_baremetal_network_provisioning_dhcp      = false # Use ironic-dnsmasq
    ocp_baremetal_network_provisioning_range     = var.network_provisioning.dhcp_range
    ocp_baremetal_hosts                          = indent(6, join("\n", 
      concat(
        data.template_file.ocp_baremetal_master_hosts.*.rendered,
        data.template_file.ocp_baremetal_worker_hosts.*.rendered
      )
    ))
    ocp_pull_secret                              = local.ocp_pull_secret_disconnected
    ocp_ssh_pubkey                               = trimspace(tls_private_key.ssh_maintuser.public_key_openssh)
    ocp_additional_ca                            = indent(2, tls_self_signed_cert.ocp_root_ca.cert_pem)
  }
}

resource "local_file" "ocp_pull_secret" {
  filename             = format("output/openshift-install/%s/pull-secret.json", var.OCP_ENVIRONMENT)
  content              = local.ocp_pull_secret_disconnected
  file_permission      = "0644"
  directory_permission = "0755"
}

resource "local_file" "ocp_install_config" {
  filename             = format("output/openshift-install/%s/install-config.yaml", var.OCP_ENVIRONMENT)
  content              = data.template_file.ocp_install_config.rendered
  file_permission      = "0644"
  directory_permission = "0755"
}

resource "local_file" "ocp_install_config_backup" {
  filename             = format("output/openshift-install/%s/install-config.yaml.backup", var.OCP_ENVIRONMENT)
  content              = data.template_file.ocp_install_config.rendered
  file_permission      = "0644"
  directory_permission = "0755"
}
