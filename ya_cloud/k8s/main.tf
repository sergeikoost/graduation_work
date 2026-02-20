############################################
# Service Accounts for Managed Kubernetes
############################################

resource "yandex_iam_service_account" "k8s_cluster_sa" {
  name = "${var.cluster_name}-cluster-sa"
}

resource "yandex_iam_service_account" "k8s_node_sa" {
  name = "${var.cluster_name}-node-sa"
}

# Роли для cluster SA (надёжный набор для диплома)
resource "yandex_resourcemanager_folder_iam_member" "cluster_sa_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster_sa.id}"
}

# Часто требуется для работы с публичной связностью/сетевыми ресурсами Managed K8s
# (YC проверяет роли сервисного аккаунта при создании кластера)
resource "yandex_resourcemanager_folder_iam_member" "cluster_sa_vpc_public_admin" {
  folder_id = var.yc_folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster_sa.id}"
}

# Роли для node SA
resource "yandex_resourcemanager_folder_iam_member" "node_sa_compute_admin" {
  folder_id = var.yc_folder_id
  role      = "compute.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_node_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "node_sa_puller" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_node_sa.id}"
}

############################################
# Security Group for K8s (минимально рабочая)
############################################

resource "yandex_vpc_security_group" "k8s" {
  name       = "${var.cluster_name}-sg"
  network_id = var.network_id

  # Внутри SG разрешаем всё (master <-> nodes, nodes <-> nodes, service traffic)
  ingress {
    protocol          = "ANY"
    from_port         = 0
    to_port           = 65535
    predefined_target = "self_security_group"
  }

  # Разрешаем Kubernetes API снаружи (временно 0.0.0.0/0; позже можно сузить до своего IP)
  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  # Иногда API доступен на 443 (зависит от реализации endpoint)
  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API (443)"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  # NodePort (на будущее, чтобы проще было выставлять сервисы наружу)
  ingress {
    protocol       = "TCP"
    description    = "NodePort range"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  # Исходящий трафик наружу
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

############################################
# Managed Kubernetes cluster (single master)
############################################

resource "yandex_kubernetes_cluster" "this" {
  name            = var.cluster_name
  network_id      = var.network_id
  release_channel = "REGULAR"

  service_account_id      = yandex_iam_service_account.k8s_cluster_sa.id
  node_service_account_id = yandex_iam_service_account.k8s_node_sa.id

  master {
    public_ip = true

    # Привязываем SG к мастеру (важно для работоспособности/доступа)
    security_group_ids = [yandex_vpc_security_group.k8s.id]

    zonal {
      zone      = "ru-central1-a"
      subnet_id = var.subnet_ids["a"]
    }
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.cluster_sa_editor,
    yandex_resourcemanager_folder_iam_member.cluster_sa_vpc_public_admin,
    yandex_resourcemanager_folder_iam_member.node_sa_compute_admin,
    yandex_resourcemanager_folder_iam_member.node_sa_puller
  ]
}

############################################
# Node group (preemptible workers)
############################################

resource "yandex_kubernetes_node_group" "workers" {
  cluster_id = yandex_kubernetes_cluster.this.id
  name       = "${var.cluster_name}-workers"

  # Версию НЕ фиксируем, чтобы не ловить deprecated
  # version = ...

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
    fixed_scale { size = 2 }
  }

  instance_template {
    platform_id = "standard-v2"

    resources {
      cores         = 2
      memory        = 4
      core_fraction = 20
    }

    boot_disk {
      type = "network-ssd"
      size = 64
    }

    scheduling_policy { preemptible = true }

    # Новый рекомендуемый способ: network_interface subnet_ids + security_group_ids
    # (subnet_id в allocation_policy сейчас deprecated у провайдера)
    network_interface {
      subnet_ids         = [var.subnet_ids["a"], var.subnet_ids["b"], var.subnet_ids["d"]]
      security_group_ids = [yandex_vpc_security_group.k8s.id]
      nat                = true
    }

    container_runtime { type = "containerd" }
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