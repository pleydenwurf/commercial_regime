# Traefik Reverse Proxy Deployment on Rocky Linux 9.6

This Ansible playbook automates the deployment of a Traefik reverse proxy with ACME SSL certificates on a Rocky Linux 9.6 VM in vSphere.

## Prerequisites

1. **Ansible Control Machine**:
   - Ansible 2.9+ installed
   - Python 3.6+ with pyvmomi library
   - SSH access to vSphere environment

2. **vSphere Environment**:
   - vCenter Server with administrative access
   - Rocky Linux 9.6 VM template prepared
   - Network connectivity and DNS configured
   - Datastore with sufficient space (40GB minimum)

3. **DNS Configuration**:
   - A records pointing to the VM's IP address:
     - `traefik.yourdomain.com` (for Traefik dashboard)
     - `app.yourdomain.com` (for sample backend service)

## Installation

1. **Install Required Collections**:
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

2. **Install Python Dependencies**:
   ```bash
   pip install pyvmomi
   ```

## Configuration

1. **Update Variables**:
   Edit `inventory.yml` and `group_vars/all.yml` with your environment details:
   - vCenter hostname and credentials
   - Domain names and email for ACME
   - Network and datastore names
   - SSH key paths

2. **Environment Variables** (optional):
   ```bash
   export VCENTER_HOST="vcenter.example.com"
   export VCENTER_USER="administrator@vsphere.local"
   export VCENTER_PASS="your_password"
   export DOMAIN="your-domain.com"
   export ACME_EMAIL="admin@your-domain.com"
   ```

3. **Vault for Sensitive Data** (recommended):
   ```bash
   ansible-vault create group_vars/all/vault.yml
   ```
   Add sensitive variables:
   ```yaml
   vault_vcenter_password: "your_vcenter_password"
   ```

## Deployment

1. **Run the Playbook**:
   ```bash
   ansible-playbook -i inventory.yml traefik-deploy.yml
   ```

2. **With Vault**:
   ```bash
   ansible-playbook -i inventory.yml traefik-deploy.yml --ask-vault-pass
   ```

## What Gets Deployed

### Infrastructure
- **VM**: Rocky Linux 9.6 with 2 CPU, 4GB RAM, 40GB disk
- **Firewall**: Configured for ports 80, 443, 8080
- **Docker**: Container runtime for Traefik and backend services

### Traefik Configuration
- **Reverse Proxy**: Automatic HTTP to HTTPS redirect
- **ACME Client**: Let's Encrypt SSL certificate automation
- **Dashboard**: Web UI for monitoring and configuration
- **Load Balancer**: Ready for multiple backend services

### Services
- **Traefik**: Main reverse proxy service
- **Nginx Backend**: Sample backend service for testing
- **Systemd Integration**: Automatic service management

## Access Points

After deployment:

- **Traefik Dashboard**: `https://traefik.yourdomain.com:8080`
  - Username: `admin`
  - Password: `admin` (change in production!)

- **Sample Backend**: `https://app.yourdomain.com`
  - Demonstrates SSL termination and proxying

- **Health Check**: `http://vm-ip:8080/ping`

## Post-Deployment Tasks

1. **Change Default Credentials**:
   ```bash
   # Generate new password hash
   htpasswd -nb admin newpassword
   
   # Update docker-compose.yml and dynamic.yml
   ```

2. **Add Additional Services**:
   ```yaml
   # Add to docker-compose.yml
   new-service:
     image: your-app:latest
     labels:
       - "traefik.enable=true"
       - "traefik.http.routers.new-service.rule=Host(`new.yourdomain.com`)"
       - "traefik.http.routers.new-service.entrypoints=websecure"
       - "traefik.http.routers.new-service.tls.certresolver=letsencrypt"
     networks:
       - traefik
   ```

3. **Configure Monitoring**:
   - Enable metrics endpoint in Traefik
   - Set up log aggregation
   - Configure alerting

## Maintenance

### Update Traefik
```bash
# On the VM
cd /opt/traefik
sudo systemctl stop traefik
sudo docker-compose pull
sudo systemctl start traefik
```

### View Logs
```bash
# Traefik logs
sudo docker logs traefik

# System logs
sudo journalctl -u traefik -f
```

### Backup SSL Certificates
```bash
# Backup ACME data
sudo cp /opt/traefik/data/acme.json /backup/location/
```

## Security Considerations

1. **Change Default Credentials**: Update dashboard authentication
2. **Firewall Rules**: Restrict access to management ports
3. **SSL Configuration**: Use strong cipher suites
4. **Access Control**: Implement IP whitelisting for sensitive services
5. **Regular Updates**: Keep Traefik and system packages updated

## Troubleshooting

### Common Issues

1. **SSL Certificate Issues**:
   - Check DNS A records
   - Verify port 80 is accessible for ACME challenge
   - Review Let's Encrypt rate limits

2. **Service Discovery**:
   - Ensure Docker socket is accessible
   - Check container labels
   - Verify network connectivity

3. **VM Deployment**:
   - Verify vCenter permissions
   - Check template availability
   - Ensure datastore space

### Logs to Check
```bash
# Traefik logs
sudo docker logs traefik

# System logs
sudo journalctl -u traefik -f

# ACME logs
sudo docker exec traefik cat /logs/traefik.log | grep acme
```

## File Structure

```
.
├── traefik-deploy.yml          # Main playbook
├── inventory.yml               # Inventory configuration
├── group_vars/
│   └── all.yml                 # Variables
├── requirements.yml            # Ansible collections
├── ansible.cfg                 # Ansible configuration
└── README.md                   # This file
```

## Support

For issues and questions:
- Check Traefik documentation: https://doc.traefik.io/traefik/
- Review Ansible VMware collection docs
- Verify Rocky Linux compatibility