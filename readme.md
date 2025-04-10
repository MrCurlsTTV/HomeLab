# Homelab Repository

This repository contains configurations and scripts for managing a homelab environment using Terraform, Ansible, and other tools. Below is an overview of the directory structure and the purpose of each component.

## Directory Structure

### `Terraform/`

Contains Terraform configurations for managing Proxmox VMs and other infrastructure.

- **`main.tf`**: Defines the Proxmox VM resources and their configurations.
- **`providers.tf`**: Specifies the Proxmox provider and Terraform Cloud backend.
- **`variables.tf`**: Declares variables for Proxmox API credentials and other configurations.
- **`locals.tf`**: Contains local variables for VM definitions.
- **`versions.tf`**: Specifies required Terraform and provider versions.
- **`sshkeys.txt`**: Stores SSH public keys for VM provisioning.

### `Ansible/`

Contains Ansible playbooks and roles for automating VM template creation.

- **`cloud_init_templates.yml`**: Main playbook for creating cloud-init VM templates.
- **`inventory/hosts.ini`**: Inventory file defining Proxmox hosts.
- **`roles/`**:
  - **`create_templates/`**: Role for creating VM templates with defined distributions.
    - **`defaults/`**: Default variables for packages and configurations.
    - **`tasks/`**: Template creation and customization tasks.

### `Ansible POC/`

Contains proof of concept Ansible playbooks for testing and development.

- **`cloud_init_role.yml`**: Proof of concept playbook for cloud-init template creation
- **`inventory/`**: Test inventory configurations
- **`roles/`**:
  - **`create_vm/`**: Role for creating and configuring VMs
    - **`tasks/`**: VM creation and customization tasks
  - **`deploy_vm/`**: Role for deploying applications to VMs
    - **`tasks/`**: Application deployment tasks

### `rsa.ps1`

PowerShell script for transferring SSH keys and updating certificates on Proxmox nodes.

## Purpose

This repository is designed to automate the management of a homelab environment, including:

- Provisioning and managing VMs on Proxmox using Terraform
- Creating and managing cloud-init templates with Ansible
- Testing new automation features in the POC environment
- Automating cluster-wide SSH key distribution
- Standardizing VM configurations across multiple nodes
- Maintaining consistent VM templates across the cluster
