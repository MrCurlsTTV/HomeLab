#!/bin/bash

# HAProxy Certificate Diagnostic Script
# This script checks all aspects of the HA certificate management system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "  $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if file exists and is readable
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        if [ -r "$file" ]; then
            print_success "$description exists and is readable"
            return 0
        else
            print_warning "$description exists but is not readable"
            return 1
        fi
    else
        print_error "$description does not exist"
        return 1
    fi
}

# Function to check if file exists and is executable
check_executable() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        if [ -x "$file" ]; then
            print_success "$description exists and is executable"
            return 0
        else
            print_warning "$description exists but is not executable"
            print_info "Permissions: $(ls -la "$file" | awk '{print $1, $3, $4}')"
            return 1
        fi
    else
        print_error "$description does not exist"
        return 1
    fi
}

# Function to check service status
check_service() {
    local service="$1"
    
    if systemctl is-active --quiet "$service"; then
        print_success "$service is running"
        if systemctl is-enabled --quiet "$service"; then
            print_info "Service is enabled for auto-start"
        else
            print_warning "Service is running but not enabled for auto-start"
        fi
    else
        print_error "$service is not running"
        print_info "Status: $(systemctl is-active "$service" 2>/dev/null || echo 'unknown')"
    fi
}

# Function to check certificate details
check_certificate() {
    local cert_file="$1"
    local description="$2"
    
    if [ -f "$cert_file" ]; then
        print_success "$description exists"
        
        # Extract certificate information
        local issuer=$(openssl x509 -in "$cert_file" -text -noout 2>/dev/null | grep "Issuer:" | sed 's/.*Issuer: //')
        local subject=$(openssl x509 -in "$cert_file" -text -noout 2>/dev/null | grep "Subject:" | sed 's/.*Subject: //')
        local not_after=$(openssl x509 -in "$cert_file" -text -noout 2>/dev/null | grep "Not After" | sed 's/.*Not After : //')
        local sans=$(openssl x509 -in "$cert_file" -text -noout 2>/dev/null | grep -A1 "Subject Alternative Name" | tail -1 | sed 's/.*DNS:/DNS:/')
        
        print_info "Issuer: $issuer"
        print_info "Subject: $subject"
        print_info "Expires: $not_after"
        
        if [[ "$issuer" == *"Let's Encrypt"* ]]; then
            print_success "Certificate is from Let's Encrypt"
        else
            print_warning "Certificate is NOT from Let's Encrypt (likely self-signed)"
        fi
        
        if [ -n "$sans" ]; then
            print_info "SAN: $sans"
        fi
        
        # Check expiration
        local exp_epoch=$(date -d "$not_after" +%s 2>/dev/null || echo 0)
        local now_epoch=$(date +%s)
        local days_left=$(( (exp_epoch - now_epoch) / 86400 ))
        
        if [ $days_left -gt 30 ]; then
            print_success "Certificate expires in $days_left days"
        elif [ $days_left -gt 7 ]; then
            print_warning "Certificate expires in $days_left days (renewal recommended)"
        else
            print_error "Certificate expires in $days_left days (urgent renewal needed)"
        fi
    else
        print_error "$description does not exist"
    fi
}

# Main diagnostic function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║           HAProxy Certificate Diagnostics           ║"
    echo "║                                                      ║"
    echo "║  Checking HA certificate management system          ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    print_info "Date: $(date)"
    print_info "Host: $(hostname)"
    print_info "User: $(whoami)"
    print_info "Working Directory: $(pwd)"
    
    # System Information
    print_header "System Information"
    print_info "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
    print_info "Kernel: $(uname -r)"
    print_info "Architecture: $(uname -m)"
    print_info "Uptime: $(uptime -p)"
    
    # Network Information
    print_header "Network Information"
    print_info "Hostname: $(hostname -f)"
    print_info "Primary IP: $(ip route get 8.8.8.8 | awk '{print $7}' | head -1)"
    
    # Check if this is primary or backup
    print_header "HA Configuration"
    if [ -f /etc/keepalived/keepalived.conf ]; then
        local ka_state=$(grep -i "state " /etc/keepalived/keepalived.conf | head -1 | awk '{print $2}')
        local ka_priority=$(grep -i "priority " /etc/keepalived/keepalived.conf | head -1 | awk '{print $2}')
        local virtual_ip=$(grep -A5 "virtual_ipaddress" /etc/keepalived/keepalived.conf | grep -E "^[[:space:]]*[0-9]" | head -1 | awk '{print $1}')
        
        print_info "Keepalived State: $ka_state"
        print_info "Keepalived Priority: $ka_priority"
        print_info "Virtual IP: $virtual_ip"
        
        if [[ "$ka_state" == "MASTER" ]]; then
            print_success "This is the PRIMARY node (should handle certificates)"
        else
            print_info "This is the BACKUP node (certificates managed by primary)"
        fi
    else
        print_error "Keepalived configuration not found"
    fi
    
    # Service Status
    print_header "Service Status"
    check_service "haproxy"
    check_service "keepalived"
    
    # Required Commands
    print_header "Required Commands"
    local commands=("openssl" "certbot" "curl" "dig" "nc" "scp" "ssh")
    for cmd in "${commands[@]}"; do
        if command_exists "$cmd"; then
            print_success "$cmd is available"
        else
            print_error "$cmd is not available"
        fi
    done
    
    # Certificate Management Scripts
    print_header "Certificate Management Scripts"
    check_executable "/usr/local/bin/request-cert.sh" "Certificate request script"
    check_executable "/usr/local/bin/cleanup-certs.sh" "Certificate cleanup script"
    check_executable "/usr/local/bin/renew-certs.sh" "Certificate renewal script"
    
    # Configuration Files
    print_header "Configuration Files"
    check_file "/etc/haproxy/haproxy.cfg" "HAProxy configuration"
    check_file "/etc/keepalived/keepalived.conf" "Keepalived configuration"
    check_file "/etc/letsencrypt/cloudflare.ini" "Cloudflare credentials"
    
    # Certificate Directories
    print_header "Certificate Directories"
    local dirs=("/etc/haproxy/certs" "/etc/letsencrypt" "/etc/letsencrypt/live" "/var/lib/letsencrypt" "/var/log/letsencrypt")
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_success "$dir exists"
            print_info "Permissions: $(ls -ld "$dir" | awk '{print $1, $3, $4}')"
            if [ "$dir" = "/etc/haproxy/certs" ] || [ "$dir" = "/etc/letsencrypt/live" ]; then
                local file_count=$(find "$dir" -type f 2>/dev/null | wc -l)
                print_info "Files in directory: $file_count"
            fi
        else
            print_error "$dir does not exist"
        fi
    done
    
    # Certificate Analysis
    print_header "Certificate Analysis"
    
    # HAProxy certificate
    if [ -f "/etc/haproxy/certs/mrcurls.org.pem" ]; then
        check_certificate "/etc/haproxy/certs/mrcurls.org.pem" "HAProxy certificate (mrcurls.org.pem)"
    else
        print_error "HAProxy certificate not found"
        print_info "Looking for any certificates in /etc/haproxy/certs/..."
        if [ -d "/etc/haproxy/certs" ]; then
            find /etc/haproxy/certs -type f -name "*.pem" 2>/dev/null | while read cert; do
                print_info "Found: $(basename "$cert")"
            done
        fi
    fi
    
    # Let's Encrypt certificates
    if [ -d "/etc/letsencrypt/live" ]; then
        local le_dirs=$(find /etc/letsencrypt/live -maxdepth 1 -type d ! -name live 2>/dev/null)
        if [ -n "$le_dirs" ]; then
            echo "$le_dirs" | while read le_dir; do
                local domain=$(basename "$le_dir")
                if [ -f "$le_dir/fullchain.pem" ]; then
                    check_certificate "$le_dir/fullchain.pem" "Let's Encrypt certificate ($domain)"
                fi
            done
        else
            print_warning "No Let's Encrypt certificates found"
        fi
    fi
    
    # HAProxy Configuration Analysis
    print_header "HAProxy Configuration Analysis"
    if [ -f "/etc/haproxy/haproxy.cfg" ]; then
        local ssl_bind=$(grep -n "ssl crt" /etc/haproxy/haproxy.cfg)
        if [ -n "$ssl_bind" ]; then
            print_success "SSL binding configured"
            print_info "$ssl_bind"
        else
            print_warning "No SSL binding found in HAProxy configuration"
        fi
        
        local cert_path=$(grep "ssl crt" /etc/haproxy/haproxy.cfg | head -1 | sed 's/.*ssl crt \([^[:space:]]*\).*/\1/')
        if [ -n "$cert_path" ]; then
            print_info "Certificate path in config: $cert_path"
            if [ -f "$cert_path" ]; then
                print_success "Certificate file exists at configured path"
            else
                print_error "Certificate file missing at configured path"
            fi
        fi
    fi
    
    # Cloudflare API Test
    print_header "Cloudflare API Test"
    if [ -f "/etc/letsencrypt/cloudflare.ini" ]; then
        local api_token=$(grep "dns_cloudflare_api_token" /etc/letsencrypt/cloudflare.ini | cut -d'=' -f2 | tr -d ' ' | tr -d '\t')
        if [ -n "$api_token" ]; then
            print_success "Cloudflare API token found"
            
            # Test API connectivity
            print_info "Testing Cloudflare API connectivity..."
            local api_response=$(curl -s -w "%{http_code}" -o /tmp/cf_test.json -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
                -H "Authorization: Bearer $api_token" \
                -H "Content-Type: application/json" 2>/dev/null || echo "000")
            
            if [ "$api_response" = "200" ]; then
                print_success "Cloudflare API token is valid"
                local token_status=$(cat /tmp/cf_test.json 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
                print_info "Token status: $token_status"
            else
                print_error "Cloudflare API token validation failed (HTTP: $api_response)"
            fi
            rm -f /tmp/cf_test.json
        else
            print_error "Cloudflare API token not found in configuration"
        fi
    else
        print_error "Cloudflare configuration file not found"
    fi
    
    # DNS Test
    print_header "DNS Resolution Test"
    local domains=("mrcurls.org" "*.mrcurls.org")
    for domain in "${domains[@]}"; do
        if [ "$domain" = "*.mrcurls.org" ]; then
            domain="test.mrcurls.org"  # Test with subdomain
        fi
        
        print_info "Testing DNS resolution for $domain..."
        local dns_result=$(dig +short "$domain" 2>/dev/null)
        if [ -n "$dns_result" ]; then
            print_success "$domain resolves to: $dns_result"
        else
            print_warning "$domain does not resolve"
        fi
    done
    
    # Network Connectivity Test
    print_header "Network Connectivity Test"
    local test_urls=("https://api.cloudflare.com" "https://acme-v02.api.letsencrypt.org")
    for url in "${test_urls[@]}"; do
        print_info "Testing connectivity to $url..."
        if curl -s --connect-timeout 5 "$url" >/dev/null 2>&1; then
            print_success "Can reach $url"
        else
            print_error "Cannot reach $url"
        fi
    done
    
    # Recent Logs
    print_header "Recent Certificate Logs"
    
    # Certificate renewal logs
    if [ -f "/var/log/cert-renewal.log" ]; then
        print_success "Certificate renewal log exists"
        print_info "Recent entries:"
        tail -10 /var/log/cert-renewal.log 2>/dev/null | while read line; do
            print_info "  $line"
        done
    else
        print_warning "Certificate renewal log not found"
    fi
    
    # Let's Encrypt logs
    if [ -f "/var/log/letsencrypt/letsencrypt.log" ]; then
        print_success "Let's Encrypt log exists"
        print_info "Recent entries:"
        tail -5 /var/log/letsencrypt/letsencrypt.log 2>/dev/null | while read line; do
            print_info "  $line"
        done
    else
        print_warning "Let's Encrypt log not found"
    fi
    
    # System logs for certificate-related entries
    print_info "Recent system logs (certificate-related):"
    journalctl --no-pager -n 5 -p warning --grep="cert\|ssl\|tls" 2>/dev/null | while read line; do
        print_info "  $line"
    done || print_info "  No recent certificate-related system logs found"
    
    # Cron Jobs
    print_header "Certificate Renewal Cron Jobs"
    local cron_jobs=$(crontab -l 2>/dev/null | grep -i cert || echo "")
    if [ -n "$cron_jobs" ]; then
        print_success "Certificate renewal cron jobs found"
        echo "$cron_jobs" | while read job; do
            print_info "$job"
        done
    else
        print_warning "No certificate renewal cron jobs found for current user"
    fi
    
    # Root cron jobs
    local root_cron=$(sudo crontab -l 2>/dev/null | grep -i cert || echo "")
    if [ -n "$root_cron" ]; then
        print_success "Root certificate renewal cron jobs found"
        echo "$root_cron" | while read job; do
            print_info "$job"
        done
    else
        print_warning "No certificate renewal cron jobs found for root user"
    fi
    

    # Summary
    print_header "Summary and Recommendations"
    
    # Determine overall status
    local issues=0
    
    if ! systemctl is-active --quiet haproxy; then
        print_error "HAProxy is not running - this needs immediate attention"
        ((issues++))
    fi
    
    if ! systemctl is-active --quiet keepalived; then
        print_error "Keepalived is not running - HA functionality compromised"
        ((issues++))
    fi
    
    if [ ! -f "/etc/haproxy/certs/mrcurls.org.pem" ]; then
        print_error "Main certificate file missing"
        ((issues++))
    elif ! openssl x509 -in "/etc/haproxy/certs/mrcurls.org.pem" -text -noout 2>/dev/null | grep -q "Let's Encrypt"; then
        print_warning "Using self-signed certificate instead of Let's Encrypt"
        ((issues++))
    fi
    
    if [ ! -x "/usr/local/bin/request-cert.sh" ]; then
        print_error "Certificate request script missing or not executable"
        ((issues++))
    fi
    
    if [ $issues -eq 0 ]; then
        print_success "No major issues detected! System appears to be working correctly."
    elif [ $issues -lt 3 ]; then
        print_warning "Some issues detected, but system is mostly functional"
    else
        print_error "Multiple issues detected - system needs attention"
    fi
    
    echo -e "\n${BLUE}Diagnostic complete. If you need to investigate further:${NC}"
    print_info "1. Check the specific error messages above"
    print_info "2. Review log files mentioned in the output"
    print_info "3. Test certificate request manually if needed"
    print_info "4. Verify Cloudflare API permissions"
    
    echo -e "\n${BLUE}For manual certificate testing, run:${NC}"
    print_info "sudo /usr/local/bin/request-cert.sh -d mrcurls.org -d '*.mrcurls.org' -e mrcurls@mrcurls.org -p 120 -c /etc/letsencrypt/cloudflare.ini -r 3 -s haproxy"
}

# Run main function
main "$@"
