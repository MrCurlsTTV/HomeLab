#!/bin/bash
# This script handles cleanup after the DNS-01 challenge

# Access environment variables provided by Certbot
DOMAIN="${CERTBOT_DOMAIN}"

echo "The challenge has been completed for ${DOMAIN}."
echo "You can now remove the _acme-challenge TXT record for this domain."

exit 0 