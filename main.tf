
locals {
  cluster_domain = "${var.cluster_name}.${var.cluster_base_domain}"
}

data "hcloud_ssh_keys" "existing" {}

data "hetznerdns_zone" "cluster" {
  name = var.cluster_base_domain
}
