############################################
# Service Accounts for Managed Kubernetes
############################################

resource "yandex_iam_service_account" "k8s_cluster_sa" {
  name = "${var.cluster_name}-cluster-sa"
}

resource "yandex_iam_service_account" "k8s_node_sa" {
  name = "${var.cluster_name}-node-sa"
}

# Для кластера
resource "yandex_resourcemanager_folder_iam_member" "cluster_sa_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster_sa.id}"
}

# Для узлов
resource "yandex_resourcemanager_folder_iam_member" "node_sa_puller" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_node_sa.id}"
}

############################################
# Managed Kubernetes cluster
############################################

resource "yandex_kubernetes_cluster" "this" {
  name       = var.cluster_name
  network_id = var.network_id

  master {
    #version   = var.k8s_version
    public_ip = true

    zonal {
      zone      = "ru-central1-a"
      subnet_id = var.subnet_ids["a"]
    }
  }

  service_account_id      = yandex_iam_service_account.k8s_cluster_sa.id
  node_service_account_id = yandex_iam_service_account.k8s_node_sa.id

  release_channel = "REGULAR"

  depends_on = [
    yandex_resourcemanager_folder_iam_member.cluster_sa_editor,
    yandex_resourcemanager_folder_iam_member.node_sa_puller
  ]
}

############################################
# Node group (preemptible workers)
############################################

resource "yandex_kubernetes_node_group" "workers" {
  cluster_id = yandex_kubernetes_cluster.this.id
  name       = "${var.cluster_name}-workers"
  #version    = var.k8s_version

  # Раскладываем ноды по подсетям/зонам
allocation_policy {
  location {
    zone      = "ru-central1-a"
    subnet_id = var.subnet_ids["a"]
  }

  location {
    zone      = "ru-central1-b"
    subnet_id = var.subnet_ids["b"]
  }

  location {
    zone      = "ru-central1-d"
    subnet_id = var.subnet_ids["d"]
  }
}

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  instance_template {
    platform_id = "standard-v2"

    resources {
      cores         = 2
      memory        = 4
      core_fraction = 20
    }

    # Минимальный размер boot disk для node group
    boot_disk {
      type = "network-ssd"
      size = 64
    }

    scheduling_policy {
      preemptible = true
    }

    # Интернет для скачивания образов
    nat = true

    container_runtime {
      type = "containerd"
    }
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  maintenance_policy {
    auto_repair  = true
    auto_upgrade = false
  }
}