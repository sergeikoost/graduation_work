output "network_id" {
  value = yandex_vpc_network.this.id
}

output "subnet_ids" {
  value = {
    a = yandex_vpc_subnet.a.id
    b = yandex_vpc_subnet.b.id
    d = yandex_vpc_subnet.d.id
  }
}
