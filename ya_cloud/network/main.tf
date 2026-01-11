resource "yandex_vpc_network" "this" {
  name = var.network_name
}

resource "yandex_vpc_subnet" "a" {
  name           = "${var.network_name}-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_subnet" "b" {
  name           = "${var.network_name}-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = ["10.20.0.0/24"]
}

resource "yandex_vpc_subnet" "c" {
  name           = "${var.network_name}-c"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = ["10.30.0.0/24"]
}

output "network_id" {
  value = yandex_vpc_network.this.id
}

output "subnet_ids" {
  value = {
    a = yandex_vpc_subnet.a.id
    b = yandex_vpc_subnet.b.id
    c = yandex_vpc_subnet.c.id
  }
}
