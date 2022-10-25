
resource "hcloud_placement_group" "master" {
  count = min(var.master_count, length(data.hcloud_datacenter.master))
  name  = "${var.cluster_name}-${var.pg_master_name}-${data.hcloud_datacenter.master[count.index].name}"
  type  = "spread"
}

resource "hcloud_placement_group" "worker" {
  count = min(var.worker_count, length(data.hcloud_datacenter.worker))
  name  = "${var.cluster_name}-${var.pg_worker_name}-${data.hcloud_datacenter.worker[count.index].name}"
  type  = "spread"
}
