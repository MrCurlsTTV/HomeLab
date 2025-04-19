# Ansible Configuration

This directory contains Ansible playbooks and roles for automating VM template creation and Kubernetes setup.

## Files

- **`cloud_init_templates.yml`**: Main playbook for creating cloud-init VM templates.
- **`inventory/hosts.ini`**: Inventory file defining Proxmox hosts.

## Roles

- **`create_templates/`**: Role for creating VM templates with defined distributions.
- **`kubectl/`**: Role for installing and configuring `kubectl` on Kubernetes nodes.
- **`rke2/`**: Role for setting up RKE2 Kubernetes clusters.
- **`helm/`**: Role for installing and configuring some helm apps.
- **`nfs/`**: Roles for configuring the NFS PVC for storage.
