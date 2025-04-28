#!/bin/bash

# Script to renew Let's Encrypt certificates and update HAProxy

# Clean up any stale Certbot processes and locks
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

# Stop HAProxy (if necessary)
# systemctl stop haproxy

# Renew certificates
echo "Renewing certificates..."
certbot renew --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini --dns-cloudflare-propagation-seconds 120 --non-interactive

# Combine certificates for HAProxy
echo "Combining certificates for HAProxy..."
for domain_dir in $(find /etc/letsencrypt/live/ -maxdepth 1 -type d | grep -v README); do
    domain_name=$(basename "$domain_dir" | sed 's/-[0-9]*$//')  # Remove suffixes like -0001
    echo "Processing certificates for domain: $domain_name (from directory: $(basename "$domain_dir"))"
    
    if [ -f "$domain_dir/fullchain.pem" ] && [ -f "$domain_dir/privkey.pem" ]; then
        cat "$domain_dir/fullchain.pem" "$domain_dir/privkey.pem" > "/etc/haproxy/certs/$domain_name.pem"
        chmod 600 "/etc/haproxy/certs/$domain_name.pem"
        echo "Created combined certificate for $domain_name"
    else
        echo "Warning: Missing certificate files in $domain_dir"
    fi
done

# Restart HAProxy to apply new certificates
echo "Reloading HAProxy..."
systemctl reload haproxy 