terraform {
  backend "remote" {
    organization = "Massbit"

    workspaces {
      name = "massbit"
    }
  }
}

provider "google" {  
  credentials = file("token.json")
  project = "massbit-indexer"  
  region  = "europe-west3"  // Germany
  zone    = "europe-west3-a"
}


resource "google_compute_instance" "default" {
  name         = "harmony-indexer"
  machine_type = "e2-highcpu-2"
  zone         = "europe-west3-a"

  tags = ["indexer"]

  boot_disk {
    initialize_params {
      # debian-9-stretch-v20210916 
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20210720"
      size = 200
    }
  }

  // Local SSD disk
  # scratch_disk {
  #   interface = "NVME"
  # }
  # │ Error: Error creating instance: googleapi: Error 400: [e2-medium, local-ssd] features are not compatible for creating instance., badRequest

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    foo = "bar"
  }

  # metadata_startup_script = file("start-up-script.sh")

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    # email  = google_service_account.default.email
    email = "hughie@massbit-indexer.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}