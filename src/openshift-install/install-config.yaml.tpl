apiVersion: v1
metadata:
  name: ${ocp_cluster_name}
baseDomain: ${ocp_dns_domain}
controlPlane:
  name: master
  hyperthreading: Enabled
  replicas: 3
compute:
  - name: worker
    hyperthreading: Enabled
    replicas: 3
platform:
  baremetal: {}
networking:
  networkType: OVNKubernetes
  machineCIDR: ${ocp_nodes_cidr}
  clusterNetwork:
    - cidr: ${ocp_pods_cidr}
      hostPrefix: ${ocp_pods_range}
  serviceNetwork:
    - ${ocp_svcs_cidr}
platform:
  baremetal:
    apiVIP: ${ocp_baremetal_api_vip}
    ingressVIP: ${ocp_baremetal_ingress_vip}
    externalBridge: ${ocp_baremetal_network_baremetal_bridge}
    provisioningNetworkCIDR: ${ocp_baremetal_network_provisioning_cidr}
    provisioningBridge: ${ocp_baremetal_network_provisioning_bridge}
    provisioningNetworkInterface: ${ocp_baremetal_network_provisioning_interface}
    provisioningDHCPExternal: ${ocp_baremetal_network_provisioning_dhcp}
    provisioningDHCPRange: ${ocp_baremetal_network_provisioning_range}
    hosts:
      ${ocp_baremetal_hosts}
pullSecret: '${ocp_pull_secret}'
sshKey: '${ocp_ssh_pubkey}'
additionalTrustBundle: |
  ${ocp_additional_ca}
