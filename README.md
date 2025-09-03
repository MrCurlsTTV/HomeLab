# Clusterio Kubernetes Infrastructure

Enterprise-grade Kubernetes GitOps platform with ArgoCD deploying media management, monitoring, authentication, and database services via Istio service mesh on RKE2 cluster.

## Overview

This project provides a comprehensive Kubernetes infrastructure running on three nodes (Alvin, Simon, Theodore) with:

- **GitOps Deployment**: ArgoCD for declarative application management
- **Service Mesh**: Istio for ingress, traffic management, and security
- **SSL Certificates**: Cert-manager with Cloudflare wildcard certificates
- **Media Management**: Servarr stack (Radarr, Sonarr, Lidarr, Bazarr, Overseerr, Prowlarr)
- **Download Clients**: Qbittorrent and NZBGet with Cloudflare proxy routing
- **Monitoring**: Prometheus, Grafana, Loki with Grafana Alloy
- **Databases**: PostgreSQL, Redis, InfluxDB with backup compression
- **Authentication**: Authentik SSO for centralized identity management
- **Storage**: NFS-based persistent volumes with high availability

## Architecture

### Infrastructure Specifications

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

### Network Configuration

- **Domain**: mrcurls.net
- **NFS Server**: 192.168.103.114
- **Storage Arrays**:
  - Vault: 2 vdevs of 4x16TB drives with special flash cache
  - Flash: Enterprise redundant storage for high IOPS

## Prerequisites

- RKE2 Kubernetes cluster running on all nodes
- kubectl configured to access the cluster
- Helm 3.x installed
- Istio CLI (istioctl) 
- Access to your Git repository
- Cloudflare API token for DNS challenges
- NFS server accessible from all nodes

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/MrCurlsTTV/homelab.git
   ```

## Service Endpoints

After successful deployment, services will be available at:

- **ArgoCD**: https://argocd.mrcurls.net
- **Authentik**: https://auth.mrcurls.net
- **Radarr**: https://radarr.mrcurls.net
- **Sonarr**: https://sonarr.mrcurls.net
- **Overseerr**: https://overseerr.mrcurls.net
- **Qbittorrent**: https://qbittorrent.mrcurls.net
- **Grafana**: https://grafana.mrcurls.net
- **Prometheus**: https://prometheus.mrcurls.net

## Storage Classes

Available storage classes for persistent volumes:

- `vault-data-nfs`: Main data storage (2TB+ volumes)
- `flash-configs-nfs`: Fast storage for configs and small data
- `influxdb-nfs`: Dedicated InfluxDB storage
- `monitoring-data-nfs`: Monitoring and metrics storage
- `etcd-nfs`: etcd backup storage

## Security Features

- **mTLS**: Strict mutual TLS between all services via Istio
- **SSO Integration**: Authentik provides OIDC/LDAP for all compatible services
- **Network Policies**: Istio authorization policies control service communication
- **SSL/TLS**: Automatic wildcard certificates from Let's Encrypt via Cloudflare DNS
- **VPN Routing**: Torrent traffic routed through CloudflareD proxy

## Backup and High Availability

- **Ceph Storage**: Distributed storage with automatic replication
- **Database Backups**: Automated compressed backups with external sync
- **Configuration Persistence**: All configurations stored on NFS
- **Multi-node**: Services can migrate between nodes during maintenance
- **HAProxy**: Virtual IP failover for external traffic

## Monitoring and Observability

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation and analysis
- **Grafana Alloy**: Unified observability agent
- **Istio Telemetry**: Service mesh metrics and tracing

## Maintenance

### Adding New Applications

1. Create application manifests in appropriate namespace directory
2. Add ArgoCD Application definition in `argocd/applications/`
3. Commit changes to Git repository
4. ArgoCD will automatically sync the new application