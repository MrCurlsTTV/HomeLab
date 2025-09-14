# Storage Requirements and Mounts

This document outlines all the storage requirements for the Clusterio Kubernetes infrastructure, including Persistent Volume Claims (PVCs), mount points, and NFS mappings.

## NFS Storage Classes Available

| Storage Class | NFS Path | Use Case | Access Mode |
|---------------|----------|----------|-------------|
| `vault-data-nfs` | `/mnt/Vault/Data` | Large data storage | ReadWriteOnce/ReadWriteMany |
| `influxdb-nfs` | `/mnt/Vault/Data/InfluxDB` | InfluxDB dedicated storage | ReadWriteOnce |
| `etcd-nfs` | `/mnt/Vault/Data/etcd` | etcd backups | ReadWriteOnce |
| `flash-configs-nfs` | `/mnt/Flash/Configs` | Configuration files (fast) | ReadWriteOnce |
| `monitoring-data-nfs` | `/mnt/Vault/Data/monitoring-data` | Monitoring data | ReadWriteOnce |

## Storage Requirements by Namespace

### Auth Namespace
| PVC Name | Size | Storage Class | Mount Path | Purpose |
|----------|------|---------------|------------|---------|
| `authentik-media` | 5Gi | flash-configs-nfs | /data/authentik/media | Authentik media files |
| `authentik-templates` | 1Gi | flash-configs-nfs | /config/authentik/templates | Custom templates |
| `authentik-certs` | 1Gi | flash-configs-nfs | /config/authentik/certs | SSL certificates |

### Database Namespace
| PVC Name | Size | Storage Class | Mount Path | Purpose |
|----------|------|---------------|------------|---------|
| `postgresql-data` | 100Gi | vault-data-nfs | /data/postgresql | PostgreSQL database |
| `postgresql-backup` | 50Gi | vault-data-nfs | /backup/postgresql | Database backups |
| `redis-data` | 10Gi | vault-data-nfs | /data/redis | Redis data |
| `redis-backup` | 5Gi | vault-data-nfs | /backup/redis | Redis backups |
| `influxdb-data` | 50Gi | influxdb-nfs | /data/influxdb | InfluxDB data |
| `influxdb-backup` | 25Gi | vault-data-nfs | /backup/influxdb | InfluxDB backups |

### Servarr Namespace (Media Management)
| PVC Name | Size | Storage Class | Mount Path | Purpose |
|----------|------|---------------|------------|---------|
| `shared-downloads` | 500Gi | vault-data-nfs | /downloads | Download staging area |
| `shared-movies` | 2Ti | vault-data-nfs | /movies | Movie library |
| `shared-tv` | 2Ti | vault-data-nfs | /tv | TV show library |
| `shared-music` | 500Gi | vault-data-nfs | /music | Music library |
| `radarr-config` | 5Gi | flash-configs-nfs | /config/radarr | Radarr configuration |
| `sonarr-config` | 5Gi | flash-configs-nfs | /config/sonarr | Sonarr configuration |
| `lidarr-config` | 5Gi | flash-configs-nfs | /config/lidarr | Lidarr configuration |
| `bazarr-config` | 2Gi | flash-configs-nfs | /config/bazarr | Bazarr configuration |
| `prowlarr-config` | 2Gi | flash-configs-nfs | /config/prowlarr | Prowlarr configuration |
| `overseerr-config` | 2Gi | flash-configs-nfs | /config/overseerr | Overseerr configuration |

### Torrents Namespace
| PVC Name | Size | Storage Class | Mount Path | Purpose |
|----------|------|---------------|------------|---------|
| `qbittorrent-config` | 5Gi | flash-configs-nfs | /config/qbittorrent | qBittorrent configuration |
| `nzbget-config` | 2Gi | flash-configs-nfs | /config/nzbget | NZBGet configuration |
| `shared-downloads` | 500Gi | vault-data-nfs | /downloads | Shared with Servarr |

### Monitoring Namespace
| PVC Name | Size | Storage Class | Mount Path | Purpose |
|----------|------|---------------|------------|---------|
| `prometheus-data` | 100Gi | monitoring-data-nfs | /data/prometheus | Prometheus metrics |
| `grafana-data` | 10Gi | monitoring-data-nfs | /data/grafana | Grafana dashboards/data |

### Vaultwarden Namespace
| PVC Name | Size | Storage Class | Mount Path | Purpose |
|----------|------|---------------|------------|---------|
| `vaultwarden-data` | 5Gi | flash-configs-nfs | /data/vaultwarden | Password vault data |

## Required NFS Mounts on Host System

Your NFS server (192.168.103.114) needs these directories available:

```bash
# Main data storage
/mnt/Vault/Data/
├── postgresql/          # PostgreSQL data and backups
├── redis/              # Redis data and backups
├── InfluxDB/           # InfluxDB dedicated storage
├── monitoring-data/    # Prometheus and Grafana data
├── etcd/              # etcd backups
├── downloads/         # Shared download staging (500GB+)
├── movies/            # Movie library (2TB+)
├── tv/                # TV show library (2TB+)
└── music/             # Music library (500GB+)

# Fast configuration storage
/mnt/Flash/Configs/
├── authentik/         # Authentik configs and media
├── radarr/           # Radarr configuration
├── sonarr/           # Sonarr configuration
├── lidarr/           # Lidarr configuration
├── bazarr/           # Bazarr configuration
├── prowlarr/         # Prowlarr configuration
├── overseerr/        # Overseerr configuration
├── qbittorrent/      # qBittorrent configuration
├── nzbget/           # NZBGet configuration
└── vaultwarden/      # Vaultwarden data
```

## Storage Optimization Notes

1. **Flash Storage**: Configuration files are stored on fast NVMe/SSD storage for quick application startup
2. **Vault Storage**: Large media files and databases use larger, slower storage with compression
3. **Shared Volumes**: Media applications share download, movie, TV, and music directories
4. **Backup Strategy**: Each database has dedicated backup storage for data protection
5. **Access Modes**: 
   - ReadWriteOnce: Single pod access (configs, databases)
   - ReadWriteMany: Multiple pod access (shared media directories)

## Total Storage Requirements

| Storage Type | Minimum Size | Recommended Size |
|--------------|-------------|------------------|
| Flash Configs | 50Gi | 100Gi |
| Vault Data | 3.5Ti | 6Ti |
| Monitoring | 150Gi | 300Gi |
| InfluxDB | 75Gi | 150Gi |

## Pre-deployment Checklist

- [ ] NFS server is running and accessible
- [ ] All required directories exist on NFS server
- [ ] NFS exports are configured with proper permissions
- [ ] Storage classes are deployed and functional
- [ ] CSI NFS driver is installed
- [ ] Test PVC creation and mounting works

## Troubleshooting Common Issues

1. **PVC Pending**: Check NFS server connectivity and CSI driver status
2. **Mount Failures**: Verify NFS export permissions (usually needs `no_root_squash`)
3. **Performance Issues**: Ensure fast storage is used for configs, slow for media
4. **Space Issues**: Monitor usage and expand volumes as needed
