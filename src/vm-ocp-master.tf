locals {
  ocp_master = [
    for index in range(var.ocp_cluster.num_masters) :
      {
        id       = format("ocp-master%02d", index)
        hostname = format("master%02d", index)
        fqdn     = format("master%02d.%s", index, var.dns.domain)
        network_baremetal = {
          ip  = lookup(var.ocp_inventory, format("master%02d", index)).network_baremetal.ip
          mac = lookup(var.ocp_inventory, format("master%02d", index)).network_baremetal.mac
        }
        network_provisioning = {
          mac = lookup(var.ocp_inventory, format("master%02d", index)).network_provisioning.mac
        }
      }
  ]
}

module "ocp_node_master" {

  source = "./modules/ocp_node"
  count  = var.ocp_cluster.num_masters

  hostname                  = local.ocp_master[count.index].hostname
  cpu                       = var.ocp_master.vcpu
  memory                    = var.ocp_master.memory
  libvirt_pool              = libvirt_pool.openshift.name
  disk_size                 = var.ocp_master.size
  network_provisioning_name = libvirt_network.ocp_provisioning.name
  network_provisioning_mac  = local.ocp_master[count.index].network_provisioning.mac
  network_baremetal_name    = libvirt_network.ocp_baremetal.name
  network_baremetal_mac     = local.ocp_master[count.index].network_baremetal.mac

}
