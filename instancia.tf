resource "google_compute_instance" "servidor" {
  name         = "servidor"
  machine_type = "n1-standard-1"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    network_ip = google_compute_address.server-ip.address
    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = "sudo apt update && sudo apt install apache2 mysql-server php php-mysql -y"

}