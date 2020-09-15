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
          mac = lookup(var.ocp_inventory, format("worker%02d", index)).network_provisioning.mac
        }
      }
  ]
}

module "ocp_node_worker" {

  source = "./modules/ocp_node"
  count  = var.ocp_cluster.num_workers

  hostname                  = local.ocp_worker[count.index].hostname
  cpu                       = var.ocp_worker.vcpu
  memory                    = var.ocp_worker.memory
  libvirt_pool              = libvirt_pool.openshift.name
  disk_size                 = var.ocp_worker.size
  network_provisioning_name = libvirt_network.ocp_provisioning.name
  network_provisioning_mac  = local.ocp_worker[count.index].network_provisioning.mac
  network_baremetal_name    = libvirt_network.ocp_baremetal.name
  network_baremetal_mac     = local.ocp_worker[count.index].network_baremetal.mac

}
