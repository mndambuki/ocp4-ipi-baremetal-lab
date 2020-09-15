resource "random_password" "bmc_ipmi_password" {
  length  = 16
  special = false
}

locals {

  bmc_ipmi_configuration = {
    protocol = "ipmi"
    ip       = var.network_baremetal.gateway
    user     = "metal3"
    pass     = random_password.bmc_ipmi_password.result
  }

  bmc_master_hosts_ipmi = [
    for index in range(var.ocp_cluster.num_masters) :
      {
        name        = local.ocp_master[index].id
        role        = "master"
        mac_address = local.ocp_master[index].network_provisioning.mac
        boot_mode   = "UEFI"
        bmc         = {
          protocol = local.bmc_ipmi_configuration.protocol
          ip       = local.bmc_ipmi_configuration.ip
          port     = tostring(6230 + index)
          path     = ""
          user     = local.bmc_ipmi_configuration.user
          pass     = local.bmc_ipmi_configuration.pass
          no_tls   = true
        }
      }
  ]

  bmc_worker_hosts_ipmi = [
    for index in range(var.ocp_cluster.num_workers) :
      {
        name        = local.ocp_worker[index].id
        role        = "worker"
        mac_address = local.ocp_worker[index].network_provisioning.mac
        boot_mode   = "UEFI"
        bmc         = {
          protocol = local.bmc_ipmi_configuration.protocol
          ip       = local.bmc_ipmi_configuration.ip
          port     = tostring(6240 + index)
          path     = ""
          user     = local.bmc_ipmi_configuration.user
          pass     = local.bmc_ipmi_configuration.pass
          no_tls   = true
        }
      }
  ]

}

module "ocp_install_ipmi" {

  source = "./modules/ocp_install"
  count = (var.ocp_cluster.bmc == "ipmi") ? 1 : 0

  cluster_name     = var.ocp_cluster.name
  dns_domain       = var.ocp_cluster.dns_domain
  nodes_cidr       = var.network_baremetal.subnet
  pods_cidr        = var.ocp_cluster.pods_cidr
  pods_range       = var.ocp_cluster.pods_range
  svcs_cidr        = var.ocp_cluster.svcs_cidr
  pull_secret      = local.ocp_pull_secret
  ssh_pubkey       = trimspace(tls_private_key.ssh_maintuser.public_key_openssh)
  additional_ca    = indent(2, tls_self_signed_cert.ocp_root_ca.cert_pem)
  platform         = {
    kind                                     = "baremetal"
    baremetal_api_vip                        = var.ocp_cluster.api_vip
    baremetal_ingress_vip                    = var.ocp_cluster.ingress_vip
    baremetal_network_baremetal_bridge       = var.network_baremetal.bridge
    baremetal_network_provisioning_cidr      = var.network_provisioning.subnet
    baremetal_network_provisioning_bridge    = var.network_provisioning.bridge
    baremetal_network_provisioning_interface = "enp1s0"
    baremetal_network_provisioning_dhcp      = false # Use ironic-dnsmasq
    baremetal_network_provisioning_range     = var.network_provisioning.dhcp_range
    baremetal_hosts                          = concat(local.bmc_master_hosts_ipmi, local.bmc_worker_hosts_ipmi)
  }
  output_folder = format("output/openshift-install/%s", var.OCP_ENVIRONMENT)

}

resource "local_file" "attach_ipmi_hosts" {
  filename             = format("output/vmbc/attach-ipmi-hosts.sh")
  content              = <<-EOF
    #!/usr/bin/env bash
    %{ for index in range(var.ocp_cluster.num_masters) }
    vbmc add \
      --address ${local.bmc_master_hosts_ipmi[index].bmc.ip} \
      --port ${local.bmc_master_hosts_ipmi[index].bmc.port} \
      --username ${local.bmc_master_hosts_ipmi[index].bmc.user} \
      --password ${local.bmc_master_hosts_ipmi[index].bmc.pass} \
      --libvirt-uri qemu:///system ${local.ocp_master[index].id} && vbmc start ${local.ocp_master[index].id}
    %{ endfor }
    %{ for index in range(var.ocp_cluster.num_workers) }
    vbmc add \
      --address ${local.bmc_worker_hosts_ipmi[index].bmc.ip} \
      --port ${local.bmc_worker_hosts_ipmi[index].bmc.port} \
      --username ${local.bmc_worker_hosts_ipmi[index].bmc.user} \
      --password ${local.bmc_worker_hosts_ipmi[index].bmc.pass} \
      --libvirt-uri qemu:///system ${local.ocp_worker[index].id} && vbmc start ${local.ocp_worker[index].id}
    %{ endfor }
  EOF
  file_permission      = "0700"
  directory_permission = "0700"
}

resource "local_file" "dettach_ipmi_hosts" {
  filename             = format("output/vmbc/dettach-ipmi-hosts.sh")
  content              = <<-EOF
    #!/usr/bin/env bash
    %{ for index in range(var.ocp_cluster.num_masters) }
    vbmc delete ${local.ocp_master[index].id}
    %{ endfor }
    %{ for index in range(var.ocp_cluster.num_workers) }
    vbmc delete ${local.ocp_worker[index].id}
    %{ endfor }
  EOF
  file_permission      = "0700"
  directory_permission = "0700"
}
