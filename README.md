# Puppet Server Docker Setup

This Docker setup creates a Puppet server (master) that your agent nodes can connect to.

## Prerequisites

- Docker and Docker Compose installed
- 2 PCs with Puppet agent already installed
- Network connectivity between the PCs and the Docker host

## Quick Start

### 1. Build and Start the Puppet Server

```bash
docker-compose up -d --build
```

### 2. Verify the Server is Running

```bash
docker-compose logs -f puppet-server
```

Wait until you see the server has started successfully.

### 3. Get the Server's IP Address

Find out the IP address of your Docker host (the machine running the Puppet server):

**Windows:**
```powershell
ipconfig
```

**Linux/Mac:**
```bash
hostname -I
```

Or get the container IP:
```bash
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' puppet-server
```

### 4. Configure Your Agent Nodes

On each of your 2 PCs with Puppet agent installed:

#### Edit the Puppet configuration

**Windows:** `C:\ProgramData\PuppetLabs\puppet\etc\puppet.conf`
**Linux:** `/etc/puppetlabs/puppet/puppet.conf`

Add or modify these lines:

```ini
[main]
    server = <PUPPET_SERVER_IP_OR_HOSTNAME>
    certname = <UNIQUE_AGENT_NAME>
    runinterval = 30m

[agent]
    server = <PUPPET_SERVER_IP_OR_HOSTNAME>
```

Replace:
- `<PUPPET_SERVER_IP_OR_HOSTNAME>` with your Docker host IP (e.g., `192.168.1.100`)
- `<UNIQUE_AGENT_NAME>` with a unique name for each agent (e.g., `agent1.local`, `agent2.local`)

#### Add hosts entry (if not using DNS)

Add the Puppet server to your hosts file:

**Windows:** `C:\Windows\System32\drivers\etc\hosts`
**Linux:** `/etc/hosts`

Add this line:
```
<PUPPET_SERVER_IP>    puppet-server puppet
```

### 5. Connect Agents to Server

On each agent PC, run:

**Windows (as Administrator):**
```powershell
puppet agent -t
```

**Linux:**
```bash
sudo puppet agent -t
```

The first run will request a certificate from the server. With autosign enabled, certificates will be automatically signed.

## Managing Agent Certificates

### List all certificates:
```bash
docker exec puppet-server puppetserver ca list --all
```

### Manually sign a certificate:
```bash
docker exec puppet-server puppetserver ca sign --certname <agent-certname>
```

### Remove a certificate:
```bash
docker exec puppet-server puppetserver ca clean --certname <agent-certname>
```

## Creating Puppet Manifests

Create manifests in `manifests/site.pp`:

```bash
docker exec puppet-server mkdir -p /etc/puppetlabs/code/environments/production/manifests
docker exec puppet-server bash -c 'cat > /etc/puppetlabs/code/environments/production/manifests/site.pp << EOF
node default {
  # Default configuration for all nodes
  file { "/tmp/hello-from-puppet":
    ensure  => present,
    content => "Hello from Puppet Server!",
  }
}

node "agent1.local" {
  # Specific configuration for agent1
  package { "vim":
    ensure => installed,
  }
}

node "agent2.local" {
  # Specific configuration for agent2
  package { "curl":
    ensure => installed,
  }
}
EOF'
```

## Troubleshooting

### Check server logs:
```bash
docker-compose logs -f puppet-server
```

### Test connectivity from agent:
```bash
telnet <PUPPET_SERVER_IP> 8140
```

### Firewall issues:
Make sure port 8140 is open on your Docker host firewall:

**Windows:**
```powershell
New-NetFirewallRule -DisplayName "Puppet Server" -Direction Inbound -Port 8140 -Protocol TCP -Action Allow
```

**Linux:**
```bash
sudo ufw allow 8140/tcp
```

## Stopping the Server

```bash
docker-compose down
```

To remove all data (certificates, code, etc.):
```bash
docker-compose down -v
```

## Security Notes

- The current setup uses autosign for all certificates (enabled in `autosign.conf`)
- For production use, disable autosign and manually sign certificates
- Consider using proper DNS names instead of IP addresses
- Use TLS certificates from a trusted CA in production

## Next Steps

1. Create Puppet modules in `/etc/puppetlabs/code/environments/production/modules/`
2. Set up environments for dev/staging/production
3. Configure Hiera for data separation
4. Set up PuppetDB for reporting and inventory
