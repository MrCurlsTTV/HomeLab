#!/bin/bash
echo "=== HAProxy Certificate Status Check ==="
echo "Date: $(date)"
echo "Host: $(hostname)"
echo "Keepalived State: $(grep 'state ' /etc/keepalived/keepalived.conf | head -1)"
echo ""

echo "=== Certificate Files ==="
echo "HAProxy Certs:"
ls -la /etc/haproxy/certs/ 2>/dev/null || echo "Directory not found"
echo ""

echo "Let's Encrypt Certs:"
ls -la /etc/letsencrypt/live/ 2>/dev/null || echo "Directory not found"
echo ""

echo "=== Certificate Details ==="
if [ -f /etc/haproxy/certs/mrcurls.org.pem ]; then
    echo "Current certificate issuer:"
    openssl x509 -in /etc/haproxy/certs/mrcurls.org.pem -text -noout | grep "Issuer:"
    echo "Current certificate subject:"
    openssl x509 -in /etc/haproxy/certs/mrcurls.org.pem -text -noout | grep "Subject:"
    echo "Certificate expires:"
    openssl x509 -in /etc/haproxy/certs/mrcurls.org.pem -text -noout | grep "Not After"
else
    echo "No certificate found at /etc/haproxy/certs/mrcurls.org.pem"
fi
echo ""

echo "=== Script Status ==="
echo "Scripts in /usr/local/bin:"
ls -la /usr/local/bin/*cert* 2>/dev/null || echo "No cert scripts found"
echo ""

echo "=== Recent Logs ==="
echo "Recent certificate-related logs:"
grep -i "cert\|ssl" /var/log/syslog | tail -5 2>/dev/null || echo "No recent logs found"
