#!/bin/bash
# Script to clean up duplicate Let's Encrypt certificates
# This helps when multiple certificate directories have been created for the same domain

# Configuration
CERT_DIR="/etc/letsencrypt"
HAPROXY_CERTS_DIR="/etc/haproxy/certs"
VERBOSE=true
DRY_RUN=false
RELOAD_SERVICE="haproxy"

# Help function
show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -d, --cert-dir DIR     Certificate directory (default: /etc/letsencrypt)"
  echo "  -h, --haproxy-dir DIR  HAProxy certificates directory (default: /etc/haproxy/certs)"
  echo "  -s, --service NAME     Service to reload after cleanup (default: haproxy)"
  echo "  -n, --dry-run          Don't actually delete anything, just show what would be done"
  echo "  -q, --quiet            Suppress verbose output"
  echo "  --help                 Show this help message"
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--cert-dir)
      CERT_DIR="$2"
      shift 2
      ;;
    -h|--haproxy-dir)
      HAPROXY_CERTS_DIR="$2"
      shift 2
      ;;
    -s|--service)
      RELOAD_SERVICE="$2"
      shift 2
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -q|--quiet)
      VERBOSE=false
      shift
      ;;
    --help)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done

# Function to log messages if verbose is enabled
log() {
  if [ "$VERBOSE" = true ]; then
    echo "$@"
  fi
}

# Function to clean up duplicate certificates for a domain
cleanup_domain_duplicates() {
  local base=$1
  log "Checking for duplicate certificates for $base..."
  
  # Find all certificate directories for this domain
  cert_dirs=($(find "$CERT_DIR/live/" -name "${base}*" -type d 2>/dev/null | sort))
  
  if [ ${#cert_dirs[@]} -le 1 ]; then
    log "No duplicate certificates found for $base"
    return 0
  fi
  
  log "Found ${#cert_dirs[@]} certificate directories for $base"
  
  # Keep the newest certificate (last in sorted list) and remove the rest
  newest_dir="${cert_dirs[-1]}"
  newest_name=$(basename "$newest_dir")
  log "Keeping newest certificate: $newest_name"
  
  for dir in "${cert_dirs[@]}"; do
    if [ "$dir" != "$newest_dir" ]; then
      dir_name=$(basename "$dir")
      log "Removing duplicate certificate: $dir_name"
      
      if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Would remove: $dir_name (renewal config, archive, and live directory)"
      else
        # Remove renewal config
        if [ -f "$CERT_DIR/renewal/$dir_name.conf" ]; then
          rm -f "$CERT_DIR/renewal/$dir_name.conf"
        fi
        
        # Remove archive
        if [ -d "$CERT_DIR/archive/$dir_name" ]; then
          rm -rf "$CERT_DIR/archive/$dir_name"
        fi
        
        # Remove live directory (which is typically a symlink)
        if [ -e "$CERT_DIR/live/$dir_name" ]; then
          rm -rf "$CERT_DIR/live/$dir_name"
        fi
      fi
    fi
  done
  
  return 0
}

# Function to combine certificates for HAProxy
combine_certificates() {
  log "Combining certificates for HAProxy..."
  
  if [ "$DRY_RUN" = true ]; then
    log "[DRY RUN] Would combine certificates for HAProxy"
    return 0
  fi
  
  # Create the HAProxy certs directory if it doesn't exist
  mkdir -p "$HAPROXY_CERTS_DIR"
  
  # Process all certificate directories
  for domain_dir in $(find "$CERT_DIR/live/" -maxdepth 1 -type d 2>/dev/null | grep -v README); do
    domain_name=$(basename "$domain_dir" | sed 's/-[0-9]*$//')  # Remove suffixes like -0001
    log "Processing certificates for domain: $domain_name (from directory: $(basename "$domain_dir"))"
    
    if [ -f "$domain_dir/fullchain.pem" ] && [ -f "$domain_dir/privkey.pem" ]; then
      cat "$domain_dir/fullchain.pem" "$domain_dir/privkey.pem" > "$HAPROXY_CERTS_DIR/$domain_name.pem"
      chmod 600 "$HAPROXY_CERTS_DIR/$domain_name.pem"
      log "Created combined certificate for $domain_name"
    else
      log "Warning: Missing certificate files in $domain_dir"
    fi
  done
}

# Main function
main() {
  log "Starting certificate cleanup process..."
  log "Certificate directory: $CERT_DIR"
  log "HAProxy certs directory: $HAPROXY_CERTS_DIR"
  
  if [ "$DRY_RUN" = true ]; then
    log "Running in DRY RUN mode - no files will be deleted"
  fi
  
  # Get list of all unique base domains (removing numeric suffixes)
  base_domains=()
  for cert_dir in $(find "$CERT_DIR/live/" -maxdepth 1 -type d 2>/dev/null | grep -v README); do
    domain=$(basename "$cert_dir" | sed 's/-[0-9]*$//')
    if [[ ! " ${base_domains[@]} " =~ " ${domain} " ]]; then
      base_domains+=("$domain")
    fi
  done
  
  log "Found ${#base_domains[@]} unique domain(s)"
  
  # Clean up duplicates for each base domain
  for domain in "${base_domains[@]}"; do
    cleanup_domain_duplicates "$domain"
  done
  
  # Combine certificates for HAProxy
  combine_certificates
  
  # Reload service if not in dry run mode
  if [ "$DRY_RUN" = false ] && [ ! -z "$RELOAD_SERVICE" ]; then
    log "Reloading service: $RELOAD_SERVICE..."
    systemctl reload "$RELOAD_SERVICE" || systemctl restart "$RELOAD_SERVICE"
  fi
  
  log "Certificate cleanup complete!"
}

# Run the main function
main 