############################
# Terraform Requirements
############################
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

############################
# Variables
############################
variable "do_token" {
  type        = string
  description = "DigitalOcean API token for Droplets/Databases/LoadBalancers."
}

variable "spaces_access_key" {
  type        = string
  description = "Access key (already created) for DigitalOcean Spaces."
  sensitive   = true
}

variable "spaces_secret_key" {
  type        = string
  description = "Secret key (already created) for DigitalOcean Spaces."
  sensitive   = true
}

variable "name_prefix" {
  type        = string
  description = "Prefix name for all infrastructure. Must be valid for DO resources (lowercase, etc.)."
}

variable "region" {
  type        = string
  description = "DigitalOcean region for Droplet, DB, and Spaces (e.g., nyc3, sfo2, ams3, etc.)."
}

variable "app_secret_key" {
  type        = string
  description = "Secret key for the Flask app stored in .env on the Droplet."
}

variable "db_name" {
  type        = string
  description = "Name of the database used by the app."
}

############################
# (Optional) Variables for VM user/password
# Not used if you only want SSH key-based access
############################
variable "vm_user" {
  type        = string
  description = "Username to create on the Droplet (if you also do a cloud-init)."
  default     = "myuser"
}

variable "vm_password" {
  type        = string
  description = "Password for the Droplet user (if needed)."
  sensitive   = true
}

############################
# Local map of DO Spaces endpoints (if region != nyc3)
############################
locals {
  do_spaces_endpoints = {
    nyc3 = "nyc3.digitaloceanspaces.com"
    sfo2 = "sfo2.digitaloceanspaces.com"
    ams3 = "ams3.digitaloceanspaces.com"
    sgp1 = "sgp1.digitaloceanspaces.com"
    fra1 = "fra1.digitaloceanspaces.com"
    # Add others if needed
  }

  # If region is not in the map, fallback to "nyc3"
  effective_spaces_endpoint = lookup(local.do_spaces_endpoints, var.region, "nyc3.digitaloceanspaces.com")
}

############################
# Provider Configuration
############################
provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.spaces_access_key
  spaces_secret_key = var.spaces_secret_key
  spaces_endpoint   = local.effective_spaces_endpoint
}

############################
# Generate a New SSH Key Pair Locally
############################
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/id_rsa"
  file_permission = "0600"
}

############################
# Create the Public Key on DigitalOcean
############################
resource "digitalocean_ssh_key" "generated_key" {
  name       = "${var.name_prefix}-ssh-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

############################
# Create a PostgreSQL Database
############################
resource "digitalocean_database_cluster" "db" {
  # Adjust name to be sure it's valid and not too long
  name       = "awsworkshopdb${var.name_prefix}"
  engine     = "pg"
  version    = "14"
  size       = "db-s-1vcpu-1gb"
  region     = var.region
  node_count = 1
}

############################
# Create a Spaces Bucket
############################
resource "digitalocean_spaces_bucket" "my_space" {
  # Bucket name must be globally unique if region is outside DO's defaults
  # Typically "lowercase-only" and up to 63 chars for S3/Spaces standards.
  name   = "${var.name_prefix}-aws-workshop"
  region = var.region
}

############################
# Create a Droplet using SSH Key
############################
resource "digitalocean_droplet" "web" {
  name   = "${var.name_prefix}-aws-workshop"
  region = var.region
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"

  depends_on = [
    digitalocean_database_cluster.db,
    digitalocean_spaces_bucket.my_space
  ]

  # Assign the created SSH key to this Droplet
  ssh_keys = [
    digitalocean_ssh_key.generated_key.fingerprint
  ]

  # --- Optional: If you want to do a cloud-init user_data script, add here ---
  # user_data = <<-CLOUDINIT
  #   #cloud-config
  #   users:
  #     - name: ${var.vm_user}
  #       shell: /bin/bash
  #       groups: [sudo]
  #       lock_passwd: false
  #       plain_text_passwd: "${var.vm_password}"
  #       sudo: ['ALL=(ALL) NOPASSWD:ALL']
  #   ssh_pwauth: true
  # CLOUDINIT

  ############################
  # Provisioners (FILE + REMOTE-EXEC)
  ############################

  provisioner "file" {
    source      = "../../backend"  # <-- Adjust path as needed
    destination = "/app/"

    connection {
      type        = "ssh"
      user        = "root"  # or "ubuntu" on some images
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = self.ipv4_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"export POSTGRES_URL='${digitalocean_database_cluster.db.host}'\" > /app/.env",
      "echo \"export POSTGRES_PORT='${digitalocean_database_cluster.db.port}'\" >> /app/.env",
      "echo \"export POSTGRES_USER='${digitalocean_database_cluster.db.user}'\" >> /app/.env",
      "echo \"export POSTGRES_DB='${var.db_name}'\" >> /app/.env",
      "echo \"export POSTGRES_PASSWORD='${digitalocean_database_cluster.db.password}'\" >> /app/.env",
      "echo \"export SPACE_NAME='${digitalocean_spaces_bucket.my_space.name}'\" >> /app/.env",
      "echo \"export DO_SPACES_KEY='${var.spaces_access_key}'\" >> /app/.env",
      "echo \"export DO_SPACES_SECRET='${var.spaces_secret_key}'\" >> /app/.env",
      "echo \"export DO_SPACES_REGION='${var.region}'\" >> /app/.env",
      "echo \"export DO_SPACES_BUCKET='${digitalocean_spaces_bucket.my_space.name}'\" >> /app/.env",
      "echo \"export APP_SECRET_KEY='${var.app_secret_key}'\" >> /app/.env",
      "cd /app",
      "nohup bash setup_dependencies.sh 2>&1 &",
      "(crontab -l 2>/dev/null; echo \"* * * * * bash /app/check_running.sh\") | crontab -"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = self.ipv4_address
    }
  }
}

############################
# Create a Load Balancer
############################
resource "digitalocean_loadbalancer" "lb" {
  name   = "${var.name_prefix}-aws-workshop"
  region = var.region

  forwarding_rule {
    entry_port      = 80
    entry_protocol  = "http"
    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/"
  }

  droplet_ids = [
    digitalocean_droplet.web.id
  ]

  depends_on = [
    digitalocean_droplet.web
  ]
}

############################
# Outputs (Optional)
############################
output "droplet_public_ip" {
  description = "Public IP address of the Droplet."
  value       = digitalocean_droplet.web.ipv4_address
}

output "load_balancer_ip" {
  description = "Public IP address of the Load Balancer."
  value       = digitalocean_loadbalancer.lb.ip
}

output "db_host" {
  description = "Host of the managed PostgreSQL database."
  value       = digitalocean_database_cluster.db.host
}

output "spaces_bucket_name" {
  description = "Name of the created Spaces bucket."
  value       = digitalocean_spaces_bucket.my_space.name
}
