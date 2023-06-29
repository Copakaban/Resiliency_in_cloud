terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = ">= 0.62.0"
    }
  }
  required_version = ">= 0.14"
}
provider "yandex" {
  token = "y0_AgAAAAA_P5JeAATuwQAAAADcgbLbL4FcwPGsTUK51oCZaaYDOTOr-dU"
  cloud_id = "b1g86c06jfc45daohlgn"
  folder_id = "b1g7p25m0jt3rdlenpmc"
  zone = "ru-central1-b"
}

resource "yandex_compute_instance" "vm" {
  count = 2
  name = "vm${count.index}"
  boot_disk {
    initialize_params {
      image_id = "fd8oshj0osht8svg6rfs"
      size = 6
    }
  }
  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
  }
  resources {
    core_fraction = 20
    cores = 2
    memory = 2
  }
  placement_policy {
    placement_group_id = "${yandex_compute_placement_group.group1.id}"
  }
  metadata = {
    user-data = file("./meta.yaml")
  }
  scheduling_policy {
    preemptible = true
  }
}
resource "yandex_compute_placement_group" "group1" {
  name = "test-pg1"
}
resource "yandex_vpc_network" "network-1" {
  name = "network1"
}
resource "yandex_vpc_subnet" "subnet-1" {
  name = "subnet1"
  zone = "ru-central1-b"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id = "${yandex_vpc_network.network-1.id}" 
}
resource "yandex_lb_network_load_balancer" "lb-1" {
  name = "lb-1"
  listener {
    name = "my-lb1"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.test-1.id
    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
resource "yandex_lb_target_group" "test-1" {
  name      = "test-1"
  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    address   = yandex_compute_instance.vm[0].network_interface.0.ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    address   = yandex_compute_instance.vm[1].network_interface.0.ip_address
  }
}