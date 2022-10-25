
resource "hcloud_network" "k3s" {
  name     = var.cluster_name
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "k3s" {
  type         = "cloud"
  network_id   = hcloud_network.k3s.id
  network_zone = "eu-central"
  ip_range     = local.k3s_subnet_ip_range
}

locals {
  k3s_subnet_ip_range = cidrsubnet(hcloud_network.k3s.ip_range, 16, 1)
}
