# 🚀 Kubernetes Infrastructure

<p align="center">
  <a href="https://github.com/rancher/rke2"><img src="https://img.shields.io/badge/Kubernetes-RKE2-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes"></a>
  <a href="https://argoproj.github.io/cd/"><img src="https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white" alt="ArgoCD"></a>
  <a href="https://istio.io/"><img src="https://img.shields.io/badge/Service%20Mesh-Istio-466BB0?style=for-the-badge&logo=istio&logoColor=white" alt="Istio"></a>
  <a href="https://www.terraform.io/"><img src="https://img.shields.io/badge/IaC-Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform"></a>
  <a href="https://www.ansible.com/"><img src="https://img.shields.io/badge/Config%20Mgmt-Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white" alt="Ansible"></a>
</p>

<p align="center">
Enterprise-grade Kubernetes GitOps platform with ArgoCD deploying media management, monitoring, authentication, and database services via Istio service mesh on RKE2 cluster.
</p>

<p align="center">
<a href="#-key-features">Features</a> • <a href="#-infrastructure">Infrastructure</a> • <a href="#-getting-started">Getting Started</a> • <a href="#-operations-guide">Operations</a> • <a href="https://github.com/MrCurlsTTV/homelab/wiki">Documentation</a>
</p>

---

## ⚡ Quick Links

| Category | Link |
|----------|------|
| 🚀 Setup | [Getting Started Guide](#-getting-started) |
| 📊 Monitor | [Service Dashboard](https://grafana.mrcurls.org) |
| 🎬 Media | [Request Portal](https://overseerr.mrcurls.org) |
| 🔐 Auth | [SSO Portal](https://auth.mrcurls.org) |
| 📦 Deploy | [ArgoCD](https://argocd.mrcurls.org) |

## 📑 Table of Contents

- [✨ Key Features](#-key-features)
- [🏗 Infrastructure](#-infrastructure)
  - [Cluster Architecture](#cluster-architecture)
  - [Storage & Networking](#storage--networking)
- [🚀 Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [🔒 Security & Backups](#-security--backups)
- [📊 Monitoring Stack](#-monitoring-stack)
- [🛠 Operations Guide](#-operations-guide)
  - [Service URLs](#service-urls)
  - [Storage Classes](#storage-classes)
  - [Maintenance Tasks](#maintenance-tasks)

## ✨ Key Features

A production-grade Kubernetes platform built for home media and infrastructure:

🔄 **Automation & GitOps**

- ArgoCD for declarative application management
- Terraform & Ansible for infrastructure provisioning
- Automated SSL certificate management

🎬 **Media Stack**

- Complete Servarr suite (Radarr, Sonarr, Lidarr, etc.)
- Qbittorrent & NZBGet with Cloudflare proxy
- Overseerr for media requests

🔒 **Enterprise Security**

- Authentik SSO for identity management
- Istio service mesh with mTLS
- Network policies and traffic encryption

📊 **Observability**

- Grafana dashboards & alerting
- Prometheus metrics collection
- Loki log aggregation

## 🏗 Infrastructure

### Cluster Architecture

- **3 Nodes**: Alvin, Simon, Theodore
  - 20 CPU cores, 64GB RAM each
  - 6TB distributed Ceph storage (2TB per node)
  - 2x 10Gb SFP+ ports with FRR/OSPF routing
  - 2x 1Gb bonded uplinks with LACP
  - 2x Thunderbolt 4 ports (configurable)

- **Virtual Machines per Node**:
  - 1 Master node: 2 CPU, 4GB RAM, 50GB storage
  - 2 Worker nodes: 4 CPU, 8GB RAM, 100GB storage each
  - HAProxy nodes (Alvin/Simon): 1 CPU, 2GB RAM, 20GB storage

### Storage & Networking

🗄️ **Storage Infrastructure**

- NFS Server: 192.168.103.114
- Vault Array: 2 vdevs of 4x16TB drives with flash cache
- Flash Array: Enterprise SSD storage for high IOPS
- Domain: mrcurls.org

📡 **Network Features**

- HAProxy load balancing with failover
- FRR/OSPF routing between nodes
- LACP bonded uplinks
- Cloudflare DNS integration

## 🚀 Getting Started

### Prerequisites

- RKE2 Kubernetes cluster
- kubectl and Helm 3.x
- Istio CLI (istioctl)
- Git repository access
- Cloudflare API token
- NFS server access

### Installation

1. **Clone**:

   ```bash
   git clone https://github.com/MrCurlsTTV/homelab.git
   ```

## 🔒 Security & Backups

🛡️ **Security Features**

- Istio service mesh with mTLS
- Authentik SSO integration
- Network policies and RBAC
- Automated SSL certificates
- VPN-routed torrent traffic

💾 **Backup Strategy**

- Distributed Ceph storage
- Automated database backups
- NFS-based persistence
- Node failover support
- HAProxy redundancy

## 📊 Monitoring Stack

- **Metrics Collection**:
  - Prometheus for metrics storage and alerting
  - Grafana Agent for node and pod metrics
- **Log Aggregation**:
  - Loki for centralized logging
  - Grafana Agent for log collection
- **Visualization**:
  - Grafana dashboards for metrics and logs
  - Integrated log-to-trace correlation
- **Tracing**: Istio telemetry with trace correlation

## 🛠 Operations Guide

### Service URLs

#### Core Services
| Service | URL | Description |
|---------|-----|-------------|
| 🔐 Authentik | [auth.mrcurls.org](https://auth.mrcurls.org) | Identity & Access Management |
| 📊 Grafana | [grafana.mrcurls.org](https://grafana.mrcurls.org) | Metrics & Monitoring |
| 📦 ArgoCD | [argocd.mrcurls.org](https://argocd.mrcurls.org) | GitOps Deployment |

#### Media Services
| Service | URL | Description |
|---------|-----|-------------|
| 🎬 Overseerr | [overseerr.mrcurls.org](https://overseerr.mrcurls.org) | Media Requests |
| 📺 Sonarr | [sonarr.mrcurls.org](https://sonarr.mrcurls.org) | TV Shows |
| 🎥 Radarr | [radarr.mrcurls.org](https://radarr.mrcurls.org) | Movies |
| 🎵 Lidarr | [lidarr.mrcurls.org](https://lidarr.mrcurls.org) | Music |
| 🔍 Prowlarr | [prowlarr.mrcurls.org](https://prowlarr.mrcurls.org) | Indexer Management |
| ⬇️ Qbittorrent | [qbittorrent.mrcurls.org](https://qbittorrent.mrcurls.org) | Download Client |

### Storage Classes

| Class Name | Purpose | Size Limit |
|------------|---------|------------|
| `vault-data-nfs` | Media storage | 2TB+ |
| `flash-configs-nfs` | App configs | <100GB |
| `monitoring-data-nfs` | Metrics | <500GB |
| `influxdb-nfs` | Time series | <200GB |
| `etcd-nfs` | Backups | <50GB |

### Maintenance Tasks

1. **Adding Applications**:
   - Create manifests in namespace directory
   - Add ArgoCD application definition
   - Commit and let ArgoCD sync

2. **Planned Upgrades**:
   - [ ] Migrate to OpenTofu
   - [ ] Split repository structure
   - [ ] Declarative Authentik deployment
   - [ ] CI/CD integration
   - [ ] Servarr template standardization
   - [ ] Templatize some of the manifests for servarr.
   - [ ] Make the Readme on Github look pretty.

