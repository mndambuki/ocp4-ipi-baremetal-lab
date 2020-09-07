# Virtual machine variables
variable "hostname" {
  description = "Hostname for the node"
  type        = string
}

variable "cpu" {
  description = "Virtual machine reserved CPU"
  type        = number
  default     = 4
}

variable "memory" {
  description = "Virtual machine reserved CPU"
  type        = number
  default     = 16384
}

# Storage variables
variable "libvirt_pool" {
  description = "Libvirt pool to create the volume"
  type        = string
  default     = "default"
}

variable "disk_size" {
  description = "Disk size in gigabytes"
  type        = number
  default     = 120
}

# Network variables
variable "network_provisioning_name" {
  description = "Name of the libvirt provisioning network"
  type        = string
  default     = "ocp-provisioning"
}

variable "network_provisioning_mac" {
  description = "MAC address of the provisioning interface"
  type        = string
}

variable "network_baremetal_name" {
  description = "Name of the libvirt baremetal network"
  type        = string
  default     = "ocp-baremetal"
}

variable "network_baremetal_mac" {
  description = "MAC address of the baremetal interface"
  type        = string
}
