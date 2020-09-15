# Openshift
variable "platform" {
  description = "Specific deployment parameters for each platform"
  #type       = object({})
}

variable "cluster_name" {
  description = "Name to identify the cluster"
  type        = string
}

variable "dns_domain" {
  description = "The DNS domain to which the cluster should belong"
  type        = string
}

variable "nodes_cidr" {
  description = "IP block address pool for machines within the cluster"
  type        = string
}

variable "pods_cidr" {
  description = "IP block address pool for pods"
  type        = string
}

variable "pods_range" {
  description = "Prefix size to allocate to each node from the CIDR"
  type        = string
}

variable "svcs_cidr" {
  description = "IP block address pool for services"
  type        = string
}

variable "pull_secret" {
  description = "The secret to use when pulling images from Docker registry"
  type        = string
}

variable "ssh_pubkey" {
  description = "SSH publick key to provide access to instances"
  type        = string
}

variable "additional_ca" {
  description = "PEM-encoded X.509 certificate bundle that will be added to the nodes' trusted certificate store"
  type        = string
}

# install-config.yaml parameters
variable "output_folder" {
  description = "Folder to store rendered content"
  type        = string
}
