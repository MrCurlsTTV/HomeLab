#!/bin/bash

# This script mounts NFS shares from a specified server to local directories.
# It should be run with sudo privileges.

# Configuration
NFS_SERVER="192.168.103.114"
LOCAL_NFS_BASE="/mnt/nfs"

# Define the mounts as an associative array: [remote_share]="local_mount_point_suffix"
declare -A NFS_MOUNTS=(
    ["/mnt/Flash/Configs"]="configs"
    ["/mnt/Flash/flashdata"]="flashdata"
    ["/mnt/Vault/Data"]="data"
    ["/mnt/Vault/Data/InfluxDB"]="influxdb"
    ["/mnt/Vault/Data/etcd"]="etcd"
    ["/mnt/Vault/Data/monitoring-data"]="monitoring"
    ["/mnt/Vault/Proxmox/Backups"]="proxmox_backups"
    ["/mnt/Vault/Proxmox/Cold"]="proxmox_cold"
)

# --- Script Logic ---

# 1. Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root or with sudo."
  exit 1
fi

# 2. Check if NFS client utilities are installed
if ! command -v showmount &> /dev/null; then
    echo "Warning: NFS utilities not found. Attempting to install..."
    # Try to detect the package manager
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y nfs-common
    elif command -v dnf &> /dev/null; then
        dnf install -y nfs-utils
    elif command -v yum &> /dev/null; then
        yum install -y nfs-utils
    else
        echo "Error: Could not determine package manager. Please install 'nfs-common' (Debian/Ubuntu) or 'nfs-utils' (RHEL/CentOS) manually."
        exit 1
    fi
fi

# 3. Mount all defined shares
echo "Starting NFS mount process for server: $NFS_SERVER"
echo "-------------------------------------------------"

for remote_share in "${!NFS_MOUNTS[@]}"; do
    local_mount_suffix="${NFS_MOUNTS[$remote_share]}"
    local_mount="${LOCAL_NFS_BASE}/${local_mount_suffix}"
    
    echo "Processing share: $remote_share -> $local_mount"

    # Create the local mount point if it doesn't exist
    if [ ! -d "$local_mount" ]; then
        echo "  -> Directory '$local_mount' not found. Creating it."
        mkdir -p "$local_mount"
        if [ $? -ne 0 ]; then
            echo "  -> Error: Failed to create directory. Skipping this mount."
            continue
        fi
    fi

    # Check if the directory is already mounted
    if mountpoint -q "$local_mount"; then
        echo "  -> '$local_mount' is already a mount point. Skipping."
    else
        # Mount the share
        echo "  -> Mounting ${NFS_SERVER}:${remote_share}..."
        mount -t nfs "${NFS_SERVER}:${remote_share}" "$local_mount"
        if [ $? -eq 0 ]; then
            echo "  -> Successfully mounted."
        else
            echo "  -> Error: Failed to mount. Please check NFS server permissions and network connectivity."
        fi
    fi
    echo "" # Newline for better readability
done

# 4. Final verification
echo "-------------------------------------------------"
echo "NFS mount process finished. Verifying active mounts from $NFS_SERVER:"
mount | grep "$NFS_SERVER" | sed 's/^/  /'
echo "-------------------------------------------------" 