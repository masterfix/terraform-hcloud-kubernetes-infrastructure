
data "hcloud_datacenter" "master" {
  count = length(var.master_datacenters)
  name  = var.master_datacenters[count.index]
}

data "hcloud_location" "master" {
  count = length(data.hcloud_datacenter.master)
  id    = data.hcloud_datacenter.master[count.index].location.id
}

data "hcloud_datacenter" "worker" {
  count = length(var.worker_datacenters)
  name  = var.worker_datacenters[count.index]
}

data "hcloud_location" "worker" {
  count = length(data.hcloud_datacenter.worker)
  id    = data.hcloud_datacenter.worker[count.index].location.id
}
