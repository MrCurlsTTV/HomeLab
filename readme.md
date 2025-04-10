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
- **`TFC/`**: Contains Docker Compose configuration for running a Terraform Cloud Agent.  

### `Ansible POC/`  

Contains Ansible proof of concept playbooks and roles for automating VM creation and deployment.  

- **`cloud_init_role.yml`**: Main playbook for creating and deploying cloud-init VM templates.  
- **`inventory/hosts.ini`**: Inventory file defining Proxmox hosts and variables.  
- **`roles/`**:  
  - **`create_vm/`**: Role for creating VM templates.  
  - **`deploy_vm/`**: Role for deploying VMs from templates.  
- **`ssh_config/`**: Contains SSH keys for accessing Proxmox nodes.  

### `rsa.ps1`  

PowerShell script for transferring SSH keys and updating certificates on Proxmox nodes.  

## Purpose  

This repository is designed to automate the management of a homelab environment, including:  

- Provisioning and managing VMs on Proxmox using Terraform.  
- Automating VM template creation and deployment with Ansible.  
- Managing SSH keys and certificates for secure access.  
