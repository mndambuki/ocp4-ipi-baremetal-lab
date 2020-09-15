resource "random_password" "bmc_redfish_password" {
  length  = 16
  special = false
}

locals {

  bmc_redfish_configuration = {
    protocol = "redfish"
    ip       = var.network_baremetal.gateway
    port     = "8000"
    user     = "metal3"
    pass     = random_password.bmc_redfish_password.result
  }

  bmc_master_hosts_redfish = [
    for index in range(var.ocp_cluster.num_masters) :
      {
        name        = local.ocp_master[index].id
        role        = "master"
        mac_address = local.ocp_master[index].network_provisioning.mac
        boot_mode   = "UEFI"
        bmc         = {
          protocol = local.bmc_redfish_configuration.protocol
          ip       = local.bmc_redfish_configuration.ip
          port     = local.bmc_redfish_configuration.port
          path     = format("/redfish/v1/Systems/%s", module.ocp_node_master[index].libvirt_domain_uuid)
          user     = local.bmc_redfish_configuration.user
          pass     = local.bmc_redfish_configuration.pass
          no_tls   = true
        }
      }
  ]

  bmc_worker_hosts_redfish = [
    for index in range(var.ocp_cluster.num_workers) :
      {
        name        = local.ocp_worker[index].id
        role        = "worker"
        mac_address = local.ocp_worker[index].network_provisioning.mac
        boot_mode   = "UEFI"
        bmc         = {
          protocol = local.bmc_redfish_configuration.protocol
          ip       = local.bmc_redfish_configuration.ip
          port     = local.bmc_redfish_configuration.port
          path     = format("/redfish/v1/Systems/%s", module.ocp_node_worker[index].libvirt_domain_uuid)
          user     = local.bmc_redfish_configuration.user
          pass     = local.bmc_redfish_configuration.pass
          no_tls   = true
        }
      }
  ]

}

module "ocp_install_redfish" {

  source = "./modules/ocp_install"
  count = (var.ocp_cluster.bmc == "redfish") ? 1 : 0

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
    baremetal_hosts                          = concat(local.bmc_master_hosts_redfish, local.bmc_worker_hosts_redfish)
  }
  output_folder = format("output/openshift-install/%s", var.OCP_ENVIRONMENT)

}

resource "local_file" "redfish_configuration" {
  filename = pathexpand("~/.config/sushyd/emulator.conf")
  content  = <<-EOF
    # Listen on all local IP interfaces
    SUSHY_EMULATOR_LISTEN_IP = u'${var.network_baremetal.gateway}'
    
    # Bind to TCP port 8000
    SUSHY_EMULATOR_LISTEN_PORT = 8000

    # Serve this SSL certificate to the clients
    SUSHY_EMULATOR_SSL_CERT = '${abspath(local_file.redfish_certificate_pem.filename)}'

    # If SSL certificate is being served, this is its RSA private key
    SUSHY_EMULATOR_SSL_KEY = '${abspath(local_file.redfish_private_key_pem.filename)}'
  EOF
  file_permission      = "0600"
  directory_permission = "0700"
}
