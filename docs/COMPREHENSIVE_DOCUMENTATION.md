# Homelab Infrastructure Documentation

## Table of Contents

1. [Overview](#overview)
2. [Terraform Infrastructure](#terraform-infrastructure)
3. [Ansible Automation](#ansible-automation)
4. [GitOps Kubernetes Components](#gitops-kubernetes-components)
5. [CI/CD Automation](#cicd-automation)
6. [Utility Scripts](#utility-scripts)
7. [Quick Start Guide](#quick-start-guide)

## Overview

This documentation covers all components, functions, and automation tools for the homelab infrastructure project. The system provides Infrastructure as Code (IaC) capabilities for managing Proxmox VMs, Kubernetes clusters, and GitOps deployments.

## Terraform Infrastructure

### Provider Configuration

#### Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `pm_api_url` | string | No | `https://192.168.103.2:8006/api2/json` | Proxmox URL |
| `pm_user` | string | Yes | `null` | Proxmox user |
| `pm_password` | string | Yes | `null` | Proxmox password (sensitive) |
| `pm_api_token_id` | string | Yes | - | Proxmox token ID |
| `pm_api_token_secret` | string | Yes | - | Proxmox token secret (sensitive) |
| `pm_tls_insecure` | bool | No | `true` | Skip TLS verification |
| `pm_parallel` | number | No | `1` | Simultaneous Proxmox requests |
| `pm_timeout` | number | No | `600` | Timeout in seconds |
| `pm_debug` | bool | No | `true` | Debug mode |
| `nfs` | string | No | `truenas.mrcurls.org` | NFS server address |

#### Example Configuration

```hcl
# terraform.tfvars
pm_api_token_id = "terraform@pam!mytoken"
pm_api_token_secret = "your-secret-token"
pm_user = "terraform@pam"
nfs = "192.168.1.100"
```

### VM Configuration

#### Predefined VM Templates

The infrastructure defines several VM types through the `proxmox_vm_qemu` local variable:

##### Kubernetes Master Nodes (200-202)
```hcl
"200" = {
    name        = "k8s-master-0"
    target_node = "alvin"
    clone       = "ubuntu-24.04-template"
    tags        = "k8s;master;ubuntu-24.04"
    memory      = 4096
    cores       = 2
    disk_size   = "50G"
    ipconfig0   = "ip=172.16.10.200/16,gw=172.16.0.1"
}
```

##### Kubernetes Worker Nodes (210-215)
```hcl
"210" = {
    name        = "k8s-worker-1"
    target_node = "alvin"
    clone       = "ubuntu-24.04-template"
    tags        = "k8s;worker;ubuntu-24.04"
    memory      = 8192
    cores       = 4
    ipconfig0   = "ip=172.16.10.210/16,gw=172.16.0.1"
}
```

##### HAProxy Load Balancers (1000-1001)
```hcl
"1000" = {
    name        = "HAProxy01"
    target_node = "alvin"
    clone       = "ubuntu-24.04-template"
    tags        = "haproxy;primary;ubuntu-24.04"
    memory      = 2048
    cores       = 1
    disk_size   = "20G"
    ipconfig0   = "ip=172.16.255.0/16,gw=172.16.0.1"
}
```

#### Deployment Commands

```bash
# Initialize Terraform
terraform init

# Plan infrastructure changes
terraform plan

# Apply infrastructure
terraform apply

# Destroy infrastructure
terraform destroy
```

## Ansible Automation

### Template Creation

#### Playbook: `cloud_init_templates.yml`

Creates VM templates for multiple Linux distributions.

##### Supported Distributions

| Distribution | Version | Codename | Template ID |
|--------------|---------|----------|-------------|
| Ubuntu | 24.10 | oracular | 9010 |
| Ubuntu | 24.04 | noble | 9011 |
| Ubuntu | 22.04 | jammy | 9012 |
| Debian | 12 | bookworm | 9003 |
| Debian | 11 | bullseye | 9004 |

##### Usage Example

```bash
# Run template creation playbook
ansible-playbook -i inventory/hosts.ini cloud_init_templates.yml

# Run for specific distribution
ansible-playbook -i inventory/hosts.ini cloud_init_templates.yml \
  --extra-vars "target_distro=ubuntu target_version=24.04"
```

##### Variables

```yaml
releases:
  - name: noble
    version: "24.04"
    distro: ubuntu
    template_vm_id: 9011
```

### Kubernetes Setup

#### Playbook: `site.yml`

Orchestrates Kubernetes cluster deployment using RKE2.

##### Execution Flow

1. **NFS Setup**: Configure NFS mounts on all nodes
2. **First Control Plane**: Initialize primary master node
3. **Stabilization**: Wait for cluster to stabilize
4. **Additional Masters**: Configure remaining control plane nodes
5. **Worker Nodes**: Join worker nodes to cluster

##### Host Groups

```ini
[rke2_servers]
k8s-master-0
k8s-master-1
k8s-master-2

[rke2_agents]
k8s-worker-1
k8s-worker-2
k8s-worker-3
k8s-worker-4
k8s-worker-5
k8s-worker-6

[kubernetes:children]
rke2_servers
rke2_agents
```

##### Usage Example

```bash
# Deploy full Kubernetes cluster
ansible-playbook -i inventory/hosts.ini site.yml

# Deploy only NFS configuration
ansible-playbook -i inventory/hosts.ini site.yml --tags nfs

# Deploy only control plane
ansible-playbook -i inventory/hosts.ini site.yml --limit rke2_servers
```

### Available Roles

#### `create_templates`
Creates and configures VM templates with cloud-init.

**Parameters:**
- `distro`: Target distribution (ubuntu/debian)
- `version`: Distribution version
- `template_vm_id`: Proxmox template ID

#### `nfs`
Configures NFS client mounts for persistent storage.

**Parameters:**
- `nfs_server`: NFS server hostname/IP
- `nfs_path`: NFS export path
- `mount_point`: Local mount point

#### `rke2`
Installs and configures RKE2 Kubernetes.

**Parameters:**
- `is_first_control_plane`: Boolean for first master node
- `rke2_version`: RKE2 version to install
- `cluster_cidr`: Pod network CIDR

## GitOps Kubernetes Components

### Infrastructure Components

#### NFS Provisioner

Provides dynamic persistent volume provisioning using NFS.

##### Files
- `rbac.yaml`: Service account and permissions
- `storageclass.yaml`: Storage class definition
- `deployment.yaml`: NFS provisioner deployment
- `kustomization.yaml`: Kustomize configuration

##### Example StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-client
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner
parameters:
  archiveOnDelete: "false"
```

##### Usage

```bash
# Apply NFS provisioner
kubectl apply -k gitops/infrastructure/nfs-provisioner/

# Create PVC using NFS storage
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
EOF
```

### Application Components

#### Monitoring Stack

Comprehensive monitoring solution with Prometheus, Grafana, and Loki.

##### Components
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation
- **PostgreSQL**: Database backend

##### Deployment

```bash
# Deploy monitoring stack
kubectl apply -k gitops/apps/monitoring/

# Access Grafana (after port-forward)
kubectl port-forward -n monitoring svc/grafana 3000:80
```

#### ArgoCD

GitOps continuous deployment platform.

##### Applications Managed
- `infrastructure`: Core infrastructure components
- `monitoring-stack`: Monitoring applications

##### Usage

```bash
# Deploy ArgoCD
kubectl apply -k gitops/apps/argocd/

# Access ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:80
```

## CI/CD Automation

### GitHub Workflows

#### ArgoCD Sync Workflow

Automatically syncs ArgoCD applications when GitOps manifests change.

##### Trigger Conditions
- Push to `main` branch
- Changes in `gitops/**` paths

##### Workflow Steps

```yaml
name: ArgoCD Sync
on:
  push:
    branches: [main]
    paths: ['gitops/**']

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Install ArgoCD CLI
        run: |
          curl -sSL -o argocd-linux-amd64 \
            https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
          sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
      
      - name: Login to ArgoCD
        run: |
          argocd login ${{ secrets.ARGOCD_SERVER }} \
            --username admin \
            --password ${{ secrets.ARGOCD_PASSWORD }} \
            --insecure
      
      - name: Sync applications
        run: |
          argocd app sync infrastructure
          argocd app sync monitoring-stack
          argocd app wait infrastructure --health --timeout 300
          argocd app wait monitoring-stack --health --timeout 300
```

##### Required Secrets
- `ARGOCD_SERVER`: ArgoCD server URL
- `ARGOCD_PASSWORD`: ArgoCD admin password

## Utility Scripts

### SSH Key Management (rsa.ps1)

PowerShell script for distributing SSH keys to Proxmox nodes and updating certificates.

#### Configuration

```powershell
# Proxmox nodes to manage
$ProxmoxNodes = @("192.168.103.2", "192.168.103.28", "192.168.103.29","192.168.103.30")

# SSH key location
$CustomSSHKeyFolder = ".\.ssh"
$SSHKeyPath = "$CustomSSHKeyFolder\id_rsa"
```

#### Functions

##### `Transfer-SSHKey`
Transfers SSH public key to specified Proxmox node.

**Parameters:**
- `Node`: Target Proxmox node IP/hostname

**Example:**
```powershell
Transfer-SSHKey -Node "192.168.103.2"
```

##### `Run-UpdateCerts`
Executes `pvecm updatecerts` on specified Proxmox node.

**Parameters:**
- `Node`: Target Proxmox node IP/hostname

**Example:**
```powershell
Run-UpdateCerts -Node "192.168.103.2"
```

#### Usage

```powershell
# Run the complete script
.\rsa.ps1

# Or run individual functions
. .\rsa.ps1
Transfer-SSHKey -Node "192.168.103.2"
Run-UpdateCerts -Node "192.168.103.2"
```

## Quick Start Guide

### Prerequisites

1. **Proxmox VE cluster** with access
2. **Terraform** >= 1.0
3. **Ansible** >= 2.9
4. **kubectl** and **ArgoCD CLI**
5. **PowerShell** (for Windows utilities)

### Step-by-Step Deployment

#### 1. Configure Proxmox Access

```bash
# Create token in Proxmox UI
# User Management → Tokens → Add

# Set environment variables
export TF_VAR_pm_api_token_id="terraform@pam!mytoken"
export TF_VAR_pm_api_token_secret="your-secret-token"
```

#### 2. Create VM Templates

```bash
cd Ansible/Template\ Creation/
ansible-playbook -i inventory/hosts.ini cloud_init_templates.yml
```

#### 3. Deploy Infrastructure

```bash
cd Terraform/
terraform init
terraform plan
terraform apply
```

#### 4. Configure Kubernetes

```bash
cd Ansible/Kubernetes/
ansible-playbook -i inventory/hosts.ini site.yml
```

#### 5. Deploy GitOps Applications

```bash
# Install ArgoCD
kubectl apply -k gitops/apps/argocd/

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available deployment/argocd-server -n argocd

# Apply infrastructure components
kubectl apply -k gitops/infrastructure/

# Apply monitoring stack
kubectl apply -k gitops/apps/monitoring/
```

### Accessing Services

```bash
# ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:80
# Open http://localhost:8080

# Grafana Dashboard  
kubectl port-forward -n monitoring svc/grafana 3000:80
# Open http://localhost:3000

# Get ArgoCD admin password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

### Troubleshooting

#### Common Issues

1. **Terraform Provider Issues**
   ```bash
   terraform init -upgrade
   ```

2. **Ansible Connection Issues**
   ```bash
   ansible-playbook -i inventory/hosts.ini site.yml -vvv
   ```

3. **Kubernetes Cluster Issues**
   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

4. **ArgoCD Sync Issues**
   ```bash
   argocd app list
   argocd app sync <app-name>
   ```

### Maintenance Operations

#### Updating Infrastructure

```bash
# Update VM configurations in locals.tf
# Apply changes
cd Terraform/
terraform plan
terraform apply
```

#### Scaling Kubernetes

```bash
# Add new worker nodes to locals.tf
# Apply infrastructure changes
terraform apply

# Update Ansible inventory
# Run Kubernetes playbook for new nodes
ansible-playbook -i inventory/hosts.ini site.yml --limit new_workers
```

#### Backup and Recovery

```bash
# Backup Terraform state
terraform state pull > terraform.tfstate.backup

# Backup Kubernetes manifests
kubectl get all --all-namespaces -o yaml > k8s-backup.yaml

# Backup ArgoCD applications
argocd app list -o yaml > argocd-apps-backup.yaml
```

---

## Support and Contributing

For issues, feature requests, or contributions, please refer to the individual component documentation in their respective directories:

- `Terraform/readme.md` - Infrastructure documentation
- `Ansible/readme.md` - Automation documentation
- `ansible-poc/readme.md` - Proof of concept documentation

This documentation provides comprehensive coverage of all components, functions, and automation tools in the homelab infrastructure project with practical examples and usage instructions.