# OCP Node Module

This Terraform module creates a libvirt guest that simulates an Openshift node in a baremetal environment.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |

## Providers

| Name | Version |
|------|---------|
| libvirt | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cpu | Virtual machine reserved CPU | `number` | `4` | no |
| disk\_size | Disk size in gigabytes | `number` | `120` | no |
| hostname | Hostname for the node | `string` | n/a | yes |
| libvirt\_pool | Libvirt pool to create the volume | `string` | `"default"` | no |
| memory | Virtual machine reserved CPU | `number` | `16384` | no |
| network\_baremetal\_mac | MAC address of the baremetal interface | `string` | n/a | yes |
| network\_baremetal\_name | Name of the libvirt baremetal network | `string` | `"ocp-baremetal"` | no |
| network\_provisioning\_mac | MAC address of the provisioning interface | `string` | n/a | yes |
| network\_provisioning\_name | Name of the libvirt provisioning network | `string` | `"ocp-provisioning"` | no |

## Outputs

No output.

## Example

Set up a `main.tf` with:

```hcl
provider "libvirt" {
  uri = "qemu:///system"
}

module "ocp_node_master" {

  source = "./modules/ocp_node"
  count  = 3

  hostname                  = format("master%02d", count.index)
  cpu                       = 4
  memory                    = 16384
  libvirt_pool              = "openshift"
  disk_size                 = 120
  network_provisioning_name = "ocp-provisioning"
  network_provisioning_mac  = format("AA:00:00:00:00:%02d", count.index)
  network_baremetal_name    = "ocp-baremetal"
  network_baremetal_mac     = format("BA:00:00:00:00:%02d", count.index)

}

```

Then run:

```console
$ terraform init
$ terraform plan
```
