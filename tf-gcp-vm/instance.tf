resource "google_compute_instance" "ubuntu" {
  name         = "kypo-lite"
  machine_type = "n2-highmem-8"
  zone         = "europe-west3-c"
  tags         = ["ssh"]

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.admin.public_key_openssh}"
  }
  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20220419"
      size  = 250
    }
  }

  network_interface {
    network = "default"

    access_config {
      # Include this section to give the VM an external IP address
    }
  }

  advanced_machine_features {
    enable_nested_virtualization = true
  }
}

resource "google_compute_firewall" "ssh" {
  name = "allow-ssh"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = "default"
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}
