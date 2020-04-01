resource "google_compute_network" "terraform-vpc" {
        name                    = "terraform-vpc"
        auto_create_subnetworks = false
    }
    
resource "google_compute_subnetwork" "subnet" {
    name          = "terraform-vpc-subnet"
    ip_cidr_range = "10.2.0.0/16"
    region        = "europe-west1"
    network       = google_compute_network.terraform-vpc.self_link
}

resource "google_compute_address" "server-ip" {
    name         = "server-ip"
    subnetwork   = google_compute_subnetwork.subnet.id
    address_type = "INTERNAL"
    address      = "10.2.0.10"
    region       = "europe-west1"
}

resource "google_compute_firewall" "terraform-allow-icmp-ssh-http" {
    name          = "terraform-allow-icmp-ssh-http"
    network       = google_compute_network.terraform-vpc.name
    source_ranges = ["0.0.0.0/0"]

    allow {
        protocol = "icmp"
    }

    allow {
        protocol = "tcp"
        ports    = ["22", "80"]
    }

}

resource "google_compute_firewall" "terraform-allow-all-internal" {
    name          = "terraform-allow-all-internal"
    network       = google_compute_network.terraform-vpc.name
    source_ranges = ["10.2.0.0/16"]

    allow {
        protocol = "icmp"
    }

    allow {
        protocol = "tcp"
        ports    = ["0-65535"]
    }

    allow {
        protocol = "udp"
        ports    = ["0-65535"]
    }

}