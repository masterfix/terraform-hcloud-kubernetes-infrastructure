
resource "hcloud_load_balancer" "master" {
  name               = "${var.cluster_name}-${var.lb_master_name}"
  load_balancer_type = var.lb_master_type
  location           = var.lb_master_location
}

resource "hcloud_load_balancer_network" "master" {
  load_balancer_id = hcloud_load_balancer.master.id
  subnet_id        = hcloud_network_subnet.k3s.id
  ip               = cidrhost(local.k3s_subnet_ip_range, 2)
}

resource "hcloud_load_balancer_target" "master" {
  count            = length(hcloud_server.master)
  load_balancer_id = hcloud_load_balancer.master.id
  type             = "server"
  server_id        = hcloud_server.master[count.index].id
  use_private_ip   = true

  depends_on = [
    hcloud_server_network.master
  ]
}

resource "hcloud_rdns" "lb_master_ipv4" {
  load_balancer_id = hcloud_load_balancer.master.id
  ip_address       = hcloud_load_balancer.master.ipv4
  dns_ptr          = "${hcloud_load_balancer.master.name}.${var.cluster_base_domain}"
}

resource "hcloud_rdns" "lb_master_ipv6" {
  load_balancer_id = hcloud_load_balancer.master.id
  ip_address       = hcloud_load_balancer.master.ipv6
  dns_ptr          = "${hcloud_load_balancer.master.name}.${var.cluster_base_domain}"
}

resource "hetznerdns_record" "lb_master_ipv4" {
  zone_id = data.hetznerdns_zone.cluster.id
  name    = hcloud_load_balancer.master.name
  value   = hcloud_load_balancer.master.ipv4
  type    = "A"
  ttl     = 60
}

resource "hetznerdns_record" "lb_master_ipv6" {
  zone_id = data.hetznerdns_zone.cluster.id
  name    = hcloud_load_balancer.master.name
  value   = hcloud_load_balancer.master.ipv6
  type    = "AAAA"
  ttl     = 60
}

resource "hcloud_load_balancer_service" "k3s" {
  load_balancer_id = hcloud_load_balancer.master.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
}
