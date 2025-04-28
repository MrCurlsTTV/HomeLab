#!/bin/bash
# Script to request a certificate using the dns-cloudflare plugin
# This script handles cleanup, timeout, and retry logic to ensure successful certificate issuance

# Configuration - Override with command line arguments
DOMAINS=()  # Array of domains to request certificates for
EMAIL=""
PROPAGATION_SECONDS=120
MAX_RETRIES=3
CREDENTIALS_FILE="/etc/letsencrypt/cloudflare.ini"
CERT_DIR="/etc/letsencrypt"
HAPROXY_CERTS_DIR="/etc/haproxy/certs"
COMBINE_FOR_HAPROXY=true
RELOAD_SERVICE=""

# Show usage information
show_usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -d, --domain DOMAIN        Domain to request certificate for (can be used multiple times)"
  echo "  -e, --email EMAIL          Email for Let's Encrypt notifications"
  echo "  -p, --propagation SECONDS  DNS propagation wait time in seconds (default: 120)"
  echo "  -c, --credentials FILE     Path to Cloudflare credentials file"
  echo "  -r, --retries COUNT        Maximum number of retries (default: 3)"
  echo "  -o, --output-dir DIR       Certificate output directory (default: /etc/letsencrypt)"
  echo "  -h, --haproxy-dir DIR      HAProxy certificates directory (default: /etc/haproxy/certs)"
  echo "  -n, --no-combine           Don't combine certificates for HAProxy"
  echo "  -s, --service NAME         Service to reload after certificate update (e.g., haproxy)"
  echo "  --help                     Show this help message"
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--domain)
      DOMAINS+=("$2")
      shift 2
      ;;
    -e|--email)
      EMAIL="$2"
      shift 2
      ;;
    -p|--propagation)
      PROPAGATION_SECONDS="$2"
      shift 2
      ;;
    -c|--credentials)
      CREDENTIALS_FILE="$2"
      shift 2
      ;;
    -r|--retries)
      MAX_RETRIES="$2"
      shift 2
      ;;
    -o|--output-dir)
      CERT_DIR="$2"
      shift 2
      ;;
    -h|--haproxy-dir)
      HAPROXY_CERTS_DIR="$2"
      shift 2
      ;;
    -n|--no-combine)
      COMBINE_FOR_HAPROXY=false
      shift
      ;;
    -s|--service)
      RELOAD_SERVICE="$2"
      shift 2
      ;;
    --help)
      show_usage
      ;;
    *)
      echo "Unknown option: $1"
      show_usage
      ;;
  esac
done

# Validate required arguments
if [ ${#DOMAINS[@]} -eq 0 ]; then
  echo "Error: At least one domain must be specified with -d or --domain"
  show_usage
fi

if [ -z "$EMAIL" ]; then
  echo "Error: Email address must be specified with -e or --email"
  show_usage
fi

# Build the domain arguments string for certbot
DOMAIN_ARGS=""
for domain in "${DOMAINS[@]}"; do
  DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
done

# Extract base domain for certificate detection
# This gets the first domain, removing any subdomain prefixes (like www. or *)
BASE_DOMAIN=$(echo "${DOMAINS[0]}" | sed -E 's/^\*\.//; s/^www\.//')

# Function to clean up stale Certbot processes and locks
cleanup_certbot() {
  echo "Cleaning up any stale Certbot processes and locks..."
  pids=$(pgrep -f certbot || echo "")
  if [ ! -z "$pids" ]; then
    echo "Killing Certbot processes: $pids"
    kill -9 $pids
  fi

  # Remove lock files
  rm -f /var/log/letsencrypt/.certbot.lock 2>/dev/null
  rm -rf /var/lib/letsencrypt/locks/* 2>/dev/null
  find /tmp -name "*certbot*" -exec rm -rf {} \; 2>/dev/null || true
}

# Function to request the certificate
request_certificate() {
  echo "Requesting certificate for ${DOMAINS[*]}..."
  
  # Determine a consistent certificate name from the base domain
  CERT_NAME="$BASE_DOMAIN"
  
  # Check if we should use --renew-by-default to avoid creating new certificates
  RENEW_OPT=""
  if find "$CERT_DIR/live/" -name "$BASE_DOMAIN*" -type d 2>/dev/null | grep -q .; then
    echo "Existing certificates found for $BASE_DOMAIN - using renewal mode"
    RENEW_OPT="--renew-by-default"
  fi
  
  timeout $((PROPAGATION_SECONDS + 60)) certbot certonly \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --dns-cloudflare \
    --dns-cloudflare-credentials "$CREDENTIALS_FILE" \
    --dns-cloudflare-propagation-seconds "$PROPAGATION_SECONDS" \
    --cert-name "$CERT_NAME" \
    $RENEW_OPT \
    $DOMAIN_ARGS
  
  return $?
}

# Function to combine certificates for HAProxy
combine_certificates() {
  if [ "$COMBINE_FOR_HAPROXY" = false ]; then
    echo "Skipping certificate combination for HAProxy (--no-combine specified)"
    return 0
  fi

  echo "Combining certificates for HAProxy in $HAPROXY_CERTS_DIR..."
  mkdir -p "$HAPROXY_CERTS_DIR"
  
  # If we know the specific domain, prioritize those certificates
  specific_dirs=()
  for pattern in "$BASE_DOMAIN" "${BASE_DOMAIN}-[0-9]*"; do
    dirs=$(find "$CERT_DIR/live/" -maxdepth 1 -name "$pattern" -type d 2>/dev/null || echo "")
    if [ ! -z "$dirs" ]; then
      specific_dirs+=($dirs)
    fi
  done
  
  # If we found matching directories, only process those
  if [ ${#specific_dirs[@]} -gt 0 ]; then
    echo "Found ${#specific_dirs[@]} matching certificate directories for $BASE_DOMAIN"
    for domain_dir in "${specific_dirs[@]}"; do
      domain_name=$(basename "$domain_dir" | sed 's/-[0-9]*$//')  # Remove suffixes like -0001
      echo "Processing certificates for domain: $domain_name (from directory: $(basename "$domain_dir"))"
      
      if [ -f "$domain_dir/fullchain.pem" ] && [ -f "$domain_dir/privkey.pem" ]; then
        cat "$domain_dir/fullchain.pem" "$domain_dir/privkey.pem" > "$HAPROXY_CERTS_DIR/$domain_name.pem"
        chmod 600 "$HAPROXY_CERTS_DIR/$domain_name.pem"
        echo "Created combined certificate for $domain_name at $HAPROXY_CERTS_DIR/$domain_name.pem"
      else
        echo "Warning: Missing certificate files in $domain_dir"
      fi
    done
  else
    # Otherwise, process all certificate directories
    echo "No specific certificate directories found for $BASE_DOMAIN, processing all directories"
    for domain_dir in $(find "$CERT_DIR/live/" -maxdepth 1 -type d 2>/dev/null | grep -v README); do
      domain_name=$(basename "$domain_dir" | sed 's/-[0-9]*$//')  # Remove suffixes like -0001
      echo "Processing certificates for domain: $domain_name (from directory: $(basename "$domain_dir"))"
      
      if [ -f "$domain_dir/fullchain.pem" ] && [ -f "$domain_dir/privkey.pem" ]; then
        cat "$domain_dir/fullchain.pem" "$domain_dir/privkey.pem" > "$HAPROXY_CERTS_DIR/$domain_name.pem"
        chmod 600 "$HAPROXY_CERTS_DIR/$domain_name.pem"
        echo "Created combined certificate for $domain_name"
      else
        echo "Warning: Missing certificate files in $domain_dir"
      fi
    done
  fi
}

# Function to clean up duplicate certificates
cleanup_duplicate_certs() {
  local base=$1
  echo "Checking for duplicate certificates for $base..."
  
  # Find all certificate directories for this domain
  cert_dirs=($(find "$CERT_DIR/live/" -name "${base}*" -type d 2>/dev/null | sort))
  
  if [ ${#cert_dirs[@]} -le 1 ]; then
    echo "No duplicate certificates found for $base"
    return 0
  fi
  
  echo "Found ${#cert_dirs[@]} certificate directories for $base"
  
  # Keep the newest certificate (last in sorted list) and remove the rest
  newest_dir="${cert_dirs[-1]}"
  newest_name=$(basename "$newest_dir")
  echo "Keeping newest certificate: $newest_name"
  
  for dir in "${cert_dirs[@]}"; do
    if [ "$dir" != "$newest_dir" ]; then
      dir_name=$(basename "$dir")
      echo "Removing duplicate certificate: $dir_name"
      
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
  done
}

# Main process
echo "Starting certificate request process for ${DOMAINS[*]}..."

# Initial cleanup
cleanup_certbot

# Try to request certificate with retries
success=false
for (( i=1; i<=MAX_RETRIES; i++ )); do
  echo "Attempt $i of $MAX_RETRIES..."
  request_certificate
  exit_code=$?
  
  if [ $exit_code -eq 0 ]; then
    echo "Certificate request successful!"
    success=true
    break
  elif [ $exit_code -eq 124 ] || [ $exit_code -eq 137 ]; then
    echo "Certificate request timed out. Cleaning up and retrying..."
    cleanup_certbot
  else
    echo "Certificate request failed with exit code $exit_code. Cleaning up and retrying..."
    cleanup_certbot
  fi
  
  # Wait between retries
  if [ $i -lt $MAX_RETRIES ]; then
    echo "Waiting 10 seconds before next attempt..."
    sleep 10
  fi
done

# Check if certificates exist
cert_exists=false
if [ "$success" = true ]; then
  cert_exists=true
else
  # Check if certificates already exist
  for pattern in "$BASE_DOMAIN" "${BASE_DOMAIN}-[0-9]*"; do
    if [ -d "$CERT_DIR/live/$pattern" ]; then
      echo "Certificates already exist for $pattern"
      cert_exists=true
      break
    fi
  done
fi

# Add call to cleanup duplicate certificates in the main function after successful certificate issuance
if [ "$cert_exists" = true ]; then
  echo "Certificates exist, cleaning up any duplicates..."
  cleanup_duplicate_certs "$BASE_DOMAIN"
  
  echo "Combining certificates for HAProxy..."
  combine_certificates
  
  # Reload service if specified
  if [ ! -z "$RELOAD_SERVICE" ]; then
    echo "Reloading service: $RELOAD_SERVICE..."
    systemctl reload "$RELOAD_SERVICE" || systemctl restart "$RELOAD_SERVICE"
  fi
  
  echo "Done!"
  exit 0
else
  echo "Failed to obtain or find certificates after $MAX_RETRIES attempts."
  exit 1
fi 