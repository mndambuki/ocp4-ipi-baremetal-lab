# Enable debug mode
variable "DEBUG" {
  description = "Enable debug mode"
  type        = bool
  default     = false
}

# Openshift version
variable "OCP_VERSION" {
  description = "Openshift version"
  type        = string
}

# Openshift environment
variable "OCP_ENVIRONMENT" {
  description = "Openshift environment"
  type        = string
}

# Libvirt configuration
variable "libvirt" {
  description = "Libvirt configuration"
  type = object({
    pool      = string,
    pool_path = string
  })
}

# DNS configuration
variable "dns" {
  description = "DNS configuration"
  type = object({
    domain = string,
    server = string
  })
}

# Libvirt network configuration for baremetal 
variable "network_baremetal" {
  description = "Configuration for provisioning network"
  type = object({
    name    = string,
    subnet  = string,
    gateway = string,
    bridge  = string
  })
}

# Libvirt network configuration for provisioning 
variable "network_provisioning" {
  description = "Configuration for baremetal network"
  type = object({
    name       = string,
    subnet     = string,
    gateway    = string,
    bridge     = string,
    dhcp_range = string
  })
}

# Openshift registry specification
variable "ocp_registry" {
  description = "Global configuration for Openshift registry"
  type = object({
    id         = string,
    base_img   = string,
    version    = string,
    username   = string,
    password   = string,
    repository = string,
    vcpu       = number,
    memory     = number,
    size       = number,
    port       = number
  })
}

variable "ocp_registry_network" {
  description = "Network configuration for Openshift registry"
  type = object({
    ip  = string,
    mac = string
  })
}

# Openshift cluster information
variable "ocp_cluster" {
  description = "Openshift cluster information"
  type        = object({
    name        = string,
    dns_domain  = string,
    pods_cidr   = string,
    pods_range  = number,
    svcs_cidr   = string,
    num_masters = number,
    num_workers = number,
    api_vip     = string,
    ingress_vip = string
  })
}

# Openshift inventory
variable "ocp_inventory" {
  description = "List of Openshift cluster nodes"
  type        = map(object({
    network_baremetal    = object({ ip=string, mac=string }),
    network_provisioning = object({ mac=string })
  }))
}

# Openshift masters specification
variable "ocp_master" {
  description = "Configuration for Openshift master virtual machine"
  type = object({
    id       = string,
    vcpu     = number,
    memory   = number,
    size     = number
  })
}

# Openshift workers specification
variable "ocp_worker" {
  description = "Configuration for Openshift worker virtual machine"
  type = object({
    id       = string,
    vcpu     = number,
    memory   = number,
    size     = number
  })
}
