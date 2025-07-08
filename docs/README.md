# Homelab Infrastructure Documentation

## Overview

This documentation provides comprehensive coverage of all components, functions, and automation tools in the homelab infrastructure project. The system enables Infrastructure as Code (IaC) management of Proxmox VMs, Kubernetes clusters, and GitOps deployments.

## Documentation

### 📋 [Comprehensive Documentation](./COMPREHENSIVE_DOCUMENTATION.md)
**Complete reference covering all components with examples and usage instructions**

- **Terraform Infrastructure**: VM provisioning, provider configuration, deployment patterns
- **Ansible Automation**: Template creation, Kubernetes setup, role orchestration  
- **GitOps Kubernetes Components**: NFS provisioner, monitoring stack, ArgoCD applications
- **CI/CD Automation**: GitHub workflows, deployment pipelines
- **Utility Scripts**: SSH key management, PowerShell automation
- **Quick Start Guide**: End-to-end deployment instructions

## Quick Navigation

### 🚀 Getting Started
1. **Prerequisites Setup**: [Comprehensive Docs - Prerequisites](./COMPREHENSIVE_DOCUMENTATION.md#prerequisites)
2. **Proxmox Configuration**: [Comprehensive Docs - Proxmox Access](./COMPREHENSIVE_DOCUMENTATION.md#1-configure-proxmox-access)
3. **Step-by-Step Deployment**: [Comprehensive Docs - Quick Start](./COMPREHENSIVE_DOCUMENTATION.md#step-by-step-deployment)

### 🏗️ Infrastructure Components

#### Terraform (Infrastructure as Code)
- **[Variable Reference](./COMPREHENSIVE_DOCUMENTATION.md#variables)**: All configurable parameters
- **[VM Templates](./COMPREHENSIVE_DOCUMENTATION.md#predefined-vm-templates)**: Kubernetes masters, workers, HAProxy
- **[Deployment Commands](./COMPREHENSIVE_DOCUMENTATION.md#deployment-commands)**: terraform init, plan, apply

#### Ansible (Configuration Management)
- **[Template Creation](./COMPREHENSIVE_DOCUMENTATION.md#template-creation)**: Multi-distribution VM templates
- **[Kubernetes Setup](./COMPREHENSIVE_DOCUMENTATION.md#kubernetes-setup)**: RKE2 cluster deployment
- **[Available Roles](./COMPREHENSIVE_DOCUMENTATION.md#available-roles)**: All automation roles

#### GitOps (Application Deployment)
- **[NFS Provisioner](./COMPREHENSIVE_DOCUMENTATION.md#nfs-provisioner)**: Dynamic storage provisioning
- **[Monitoring Stack](./COMPREHENSIVE_DOCUMENTATION.md#monitoring-stack)**: Prometheus, Grafana, Loki
- **[ArgoCD](./COMPREHENSIVE_DOCUMENTATION.md#argocd)**: Continuous deployment

### 📊 Monitoring & Operations

#### Observability Stack
```bash
# Access Grafana Dashboard
kubectl port-forward -n monitoring svc/grafana 3000:80

# Access Prometheus Metrics
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Access ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:80
```

#### Common Operations
- **[Infrastructure Updates](./COMPREHENSIVE_DOCUMENTATION.md#updating-infrastructure)**: Modifying VM configurations
- **[Kubernetes Scaling](./COMPREHENSIVE_DOCUMENTATION.md#scaling-kubernetes)**: Adding/removing nodes
- **[Backup Procedures](./COMPREHENSIVE_DOCUMENTATION.md#backup-and-recovery)**: State and manifest backups

## Component Reference Summary

### Terraform Components

| Component | Variables | Default Values | Description |
|-----------|-----------|----------------|-------------|
| **Proxmox Provider** | `pm_api_url`, `pm_api_token_id` | `https://192.168.103.2:8006/api2/json` | Proxmox VE connection |
| **VM Configuration** | `proxmox_vm_qemu` locals | See [VM Templates](./COMPREHENSIVE_DOCUMENTATION.md#predefined-vm-templates) | Predefined VM specifications |
| **Network Settings** | `ipconfig0` | `172.16.0.0/16` network | Static IP assignments |

### Ansible Components

| Role | Variables | Default Values | Description |
|------|-----------|----------------|-------------|
| **create_templates** | `releases[]` | Ubuntu 24.04/22.04, Debian 12/11 | VM template creation |
| **rke2** | `rke2_version`, `cluster_config` | `v1.28.8+rke2r1` | Kubernetes cluster |
| **nfs** | `nfs_server`, `nfs_exports[]` | `truenas.mrcurls.org` | Storage configuration |

### Kubernetes Components

| Component | Namespace | Resources | Description |
|-----------|-----------|-----------|-------------|
| **NFS Provisioner** | `kube-system` | Deployment, RBAC, StorageClass | Dynamic PV provisioning |
| **Monitoring** | `monitoring` | Prometheus, Grafana, Loki, PostgreSQL | Observability stack |
| **ArgoCD** | `argocd` | Applications, Projects | GitOps platform |

## Environment Configuration

### Development Environment
```bash
# Use development overlays
kubectl apply -k gitops/infrastructure/nfs-provisioner/overlays/dev/
kubectl apply -k gitops/apps/monitoring/overlays/dev/
```

### Production Environment  
```bash
# Use production overlays
kubectl apply -k gitops/infrastructure/nfs-provisioner/overlays/prod/
kubectl apply -k gitops/apps/monitoring/overlays/prod/
```

## Troubleshooting Quick Reference

### Common Issues

| Issue | Quick Fix | Detailed Reference |
|-------|-----------|-------------------|
| **Terraform Provider Error** | `terraform init -upgrade` | [Comprehensive Docs - Troubleshooting](./COMPREHENSIVE_DOCUMENTATION.md#terraform-provider-issues) |
| **Ansible Connection Failed** | Check SSH keys, inventory | [Comprehensive Docs - Troubleshooting](./COMPREHENSIVE_DOCUMENTATION.md#ansible-connection-issues) |
| **PVC Pending State** | Verify NFS connectivity | [Comprehensive Docs - Troubleshooting](./COMPREHENSIVE_DOCUMENTATION.md#kubernetes-cluster-issues) |
| **ArgoCD Sync Failed** | Check resource conflicts | [Comprehensive Docs - Troubleshooting](./COMPREHENSIVE_DOCUMENTATION.md#argocd-sync-issues) |

### Health Checks

```bash
# Infrastructure Health
terraform plan                                    # Check Terraform state
ansible-playbook -i inventory/hosts.ini site.yml --check  # Ansible dry run

# Kubernetes Health  
kubectl get nodes                                 # Check node status
kubectl get pods --all-namespaces               # Check pod health
argocd app list                                  # Check ArgoCD applications
```

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Terraform     │────▶│    Proxmox VE    │────▶│   VM Templates  │
│   (IaC)         │    │   Hypervisor     │    │   (Cloud-Init)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│     Ansible     │────▶│  Kubernetes VMs  │────▶│   RKE2 Cluster  │
│  (Config Mgmt)  │    │   (Ubuntu 24.04) │    │   (HA Masters)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│     GitOps      │────▶│     ArgoCD       │────▶│  Applications   │
│  (Deployment)   │    │   (CD Platform)  │    │  (Monitoring)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Contributing

When adding new components or modifying existing ones:

1. **Update API Documentation**: Add new variables, functions, or usage examples
2. **Update Role Reference**: Document any new Ansible roles or modifications  
3. **Update GitOps Reference**: Add new Kubernetes manifests or ArgoCD applications
4. **Test Documentation**: Verify all examples work as documented
5. **Update Index**: Add new components to this overview

## Support

For issues or questions:

1. **Check Troubleshooting Guides**: Each documentation file includes troubleshooting sections
2. **Review Examples**: All APIs include working examples with expected outputs
3. **Validate Configuration**: Use provided health check commands
4. **Check Component Logs**: Detailed logging information in each component section

---

**Last Updated**: Generated comprehensive documentation covering all components, functions, and automation tools with practical examples and usage instructions.

**Coverage**: 
- ✅ Terraform Infrastructure Components (100%)
- ✅ Ansible Automation Tools (100%)  
- ✅ GitOps Kubernetes Components (100%)
- ✅ CI/CD Automation (100%)
- ✅ Utility Scripts (100%)
- ✅ Usage Examples & Troubleshooting (100%)