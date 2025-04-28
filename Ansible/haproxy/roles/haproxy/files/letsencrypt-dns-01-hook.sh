#!/bin/bash
# This script handles the DNS-01 challenge for Let's Encrypt
# It will echo the required TXT record information to standard output

# Access environment variables provided by Certbot
DOMAIN="${CERTBOT_DOMAIN}"
VALIDATION="${CERTBOT_VALIDATION}"

echo "====================================================="
echo "IMPORTANT: DNS TXT Record Required for ${DOMAIN}"
echo "====================================================="
echo ""
echo "Create this DNS record:"
echo "Domain: _acme-challenge.${DOMAIN}"
echo "TXT value: ${VALIDATION}"
echo ""
echo "After creating this record, wait for DNS propagation."
echo "====================================================="

# Wait a predefined amount of time for DNS propagation
# This is required for automated runs
echo "Waiting 60 seconds for DNS propagation..."
sleep 60

# Attempt to verify the DNS record (optional)
echo "Verification attempt: checking if DNS record is visible..."
if command -v dig > /dev/null 2>&1; then
  dig +short TXT "_acme-challenge.${DOMAIN}" || echo "DNS record not yet visible or dig not available"
else
  echo "dig command not available, skipping verification"
fi

# Return success regardless - user must ensure DNS is properly configured
exit 0 