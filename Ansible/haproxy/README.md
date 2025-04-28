# HAProxy Configuration with Let's Encrypt, Cloudflare, High Availability, and Prometheus Monitoring

This Ansible role configures HAProxy as a high-availability load balancer for Kubernetes services with automatic SSL certificate management using Let's Encrypt and Cloudflare DNS verification. It also includes Prometheus exporters for monitoring.

## Features

- HAProxy installation and configuration for Kubernetes services
- High availability setup with Keepalived for automatic failover
- Automatic SSL certificate generation and renewal with Let's Encrypt
- Cloudflare DNS verification for wildcard certificates 
- Redirects HTTP to HTTPS for secure access
- Custom error pages for better user experience
- HAProxy statistics page for monitoring
- Prometheus exporters for metrics collection

## Prerequisites

- Ubuntu servers (minimum 2 for high availability)
- Ansible 2.9+
- Cloudflare API key and email
- Domain managed by Cloudflare

## High Availability Architecture

The setup uses:
- Multiple HAProxy instances (typically 2) for redundancy
- Keepalived for VRRP (Virtual Router Redundancy Protocol)
- Floating virtual IP that automatically moves between nodes
- Automatic health checks to detect and respond to failures

## Monitoring

The role includes:
- HAProxy Exporter (port 9101) - Collects HAProxy metrics
- Node Exporter (port 9100) - Collects system metrics

Metrics can be scraped by an external Prometheus server using these endpoints:
- http://[haproxy-server]:9101/metrics - HAProxy metrics
- http://[haproxy-server]:9100/metrics - Node metrics

## Kubernetes Node Registration

This HAProxy setup is optimized for Kubernetes cluster formation and node registration, providing:

- **High Availability Control Plane Endpoint**: A stable virtual IP for Kubernetes API access
- **Load Balancing**: Distributes API server traffic across all control plane nodes
- **Failover Protection**: Ensures continuous API availability even if one HAProxy server fails
- **TLS Termination**: Optional SSL termination for the Kubernetes API (6443)

### Using with Kubernetes Cluster Creation

1. Set up the HAProxy servers first, before creating your Kubernetes cluster
2. When initializing your Kubernetes control plane, use the HAProxy virtual IP:

   ```bash
   # For installers like RKE2, K3s, etc.
   # Use the HAProxy virtual IP ({{ virtual_ip }}) as the server endpoint
   ```

3. For joining worker nodes, use the same HAProxy virtual IP in your join commands

### Key Considerations

- Make sure the Kubernetes API servers are properly defined in your inventory
- Only control plane nodes should be used for API server balancing
- The floating VIP must be reachable from all Kubernetes nodes
- Health checks ensure traffic only goes to functioning control plane nodes

## Configuration

The configuration is split between regular and sensitive variables:

### Regular Configuration Variables

Update the following variables in `group_vars/all/main.yml`:

- `domain_name`: Primary domain for SSL certificates
- `additional_domains`: Additional domains/subdomains for certificates
- `virtual_ip`: The floating IP address to be used for high availability
- Other general configuration options

### Sensitive Variables

Sensitive information is stored in `group_vars/all/vault.yml`:

- `vault_letsencrypt_email`: Email address for Let's Encrypt notifications
- `vault_cloudflare_email`: Email associated with your Cloudflare account
- `vault_cloudflare_api_key`: Your Cloudflare API key
- `vault_cloudflare_zone_id`: Your Cloudflare zone ID
- `vault_keepalived_auth_pass`: Strong password for Keepalived authentication
- `vault_haproxy_stats_password`: Password for HAProxy statistics page

For security, we recommend encrypting the vault.yml file with Ansible Vault:

```bash
ansible-vault encrypt group_vars/all/vault.yml
```

## Usage

1. Update the inventory file with your HAProxy server details
2. Customize `group_vars/all/main.yml` with your domain and HA information
3. Add your sensitive information to `group_vars/all/vault.yml`
4. Optionally encrypt the vault file with `ansible-vault encrypt group_vars/all/vault.yml`
5. Run the playbook:
   - If you didn't encrypt the vault file: `ansible-playbook -i inventory/hosts.yml site.yml`
   - If you encrypted the vault file: `ansible-playbook -i inventory/hosts.yml site.yml --ask-vault-pass`

## Maintenance

- Certificates will automatically renew via a weekly cron job
- Health checks continuously monitor HAProxy status
- Automatic failover occurs if the primary node becomes unavailable

## Security Notes

- The `group_vars/all/vault.yml` file should be excluded from version control using .gitignore
- If you need to share the encrypted vault file with team members, share the vault password securely
- For production environments, consider using Ansible Vault with a password file that's excluded from version control 