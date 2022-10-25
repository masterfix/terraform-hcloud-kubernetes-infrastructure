
variable "hcloud_token" {
  description = "Access token for communication with the Hetzner Cloud Api."
  type      = string
  sensitive = true
}

variable "hetzner_dns_token" {
  description = "Access token for communication with the Hetzner DNS Api."
  sensitive = true
  type      = string
}

variable "cluster_name" {
  description = "Name of the cluster (without domain)."
  type    = string
  default = "cluster"
}

variable "cluster_base_domain" {
  description = "Domain of the cluster (eg. example.com)."
  type    = string
  default = "local"
}

variable "fw_master_name" {
  description = "Name of the Firewall for the master machines."
  type    = string
  default = "master"
}

variable "fw_worker_name" {
  description = "Name of the Firewall for the worker machines."
  type    = string
  default = "worker"
}

variable "lb_master_name" {
  description = "Name of the admin load balancer."
  type    = string
  default = "admin"
}

variable "lb_master_type" {
  description = "Type of the load balancer for the master machines."
  type    = string
  default = "lb11"
}

variable "lb_master_location" {
  description = "Location of the load balancer for the master machines."
  type    = string
  default = "nbg1"
}

variable "master_datacenters" {
  description = "List of data centers for the master machines."
  type    = list(string)
  default = ["nbg1-dc3", "fsn1-dc14", "hel1-dc2"]
}

variable "worker_datacenters" {
  description = "List of data centers for the worker machines."
  type    = list(string)
  default = ["nbg1-dc3", "fsn1-dc14", "hel1-dc2"]
}

variable "pg_master_name" {
  description = "Name prefix of the placement groups for the master machines."
  type    = string
  default = "master"
}

variable "pg_worker_name" {
  description = "Name prefix of the placement groups for the worker machines."
  type    = string
  default = "worker"
}

variable "master_count" {
  description = "Amount of master machines."
  type    = number
  default = 3
}

variable "master_image" {
  description = "Image of the master machines."
  type    = string
  default = "debian-11"
}

variable "master_type" {
  description = "Machine type of the master machines."
  type    = string
  default = "cx11"
}

variable "master_name" {
  description = "Name prefix of the master machines."
  type    = string
  default = "master"
}

variable "worker_count" {
  description = "Amount of worker machines."
  type    = number
  default = 3
}

variable "worker_image" {
  description = "Image of the worker machines."
  type    = string
  default = "debian-11"
}

variable "worker_type" {
  description = "Machine type of the worker machines."
  type    = string
  default = "cx11"
}

variable "worker_name" {
  description = "Name prefix of the worker machines."
  type    = string
  default = "worker"
}
