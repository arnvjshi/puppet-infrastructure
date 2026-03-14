# Puppet Manifest Guide

This guide explains how to deploy and use the Puppet manifest files with your agent nodes.

## Files Created

1. **site.pp** - Main Puppet manifest that defines what should be applied to your agents
2. **system-info.epp** - EPP template for generating system information
3. **deploy-manifest.ps1** - PowerShell script to deploy manifests to the Puppet server

## What the Manifest Does

The `site.pp` manifest configures your agent nodes to:

### All Nodes (Default Configuration)
- Creates a directory: `C:\puppet-test\`
- Creates a welcome file: `C:\puppet-test\welcome.txt`
- Creates a system information file: `C:\puppet-test\system-info.txt` with details about the agent
- Displays notification messages

### Agent 1 Specific
- Creates: `C:\puppet-test\agent1-config.txt`
- Identifies as "Web Server" role
- Additional notifications

### Agent 2 Specific
- Creates: `C:\puppet-test\agent2-config.txt`
- Identifies as "Database Server" role
- Creates: `C:\puppet-test\scheduled-tasks.txt`
- Additional notifications

## Deployment Steps

### Step 1: Deploy the Manifest to Puppet Server

Run the deployment script:

```powershell
.\deploy-manifest.ps1
```

This will copy the manifest files into the running Puppet server container.

### Step 2: Test on Your Agents

On each of your agent PCs, run:

```powershell
puppet agent -t
```

This will:
1. Connect to the Puppet server
2. Download and apply the manifest
3. Create all the configured files
4. Show you what was changed

### Step 3: Verify the Results

Check that the files were created on each agent:

```powershell
dir C:\puppet-test\
type C:\puppet-test\welcome.txt
type C:\puppet-test\system-info.txt
```

## Customizing the Manifest

### Change Node Names

Edit the node definitions in `site.pp` to match your actual agent hostnames:

```puppet
node 'your-actual-hostname' {
  # configuration here
}
```

To find your agent's hostname, run on the agent PC:
```powershell
hostname
```

### Add More Files

Add more file resources:

```puppet
file { 'C:/path/to/file.txt':
  ensure  => file,
  content => "Your content here",
}
```

### Install Packages

If you have Chocolatey installed on your Windows agents:

```puppet
package { 'googlechrome':
  ensure   => installed,
  provider => chocolatey,
}
```

### Manage Services

```puppet
service { 'wuauserv':  # Windows Update service
  ensure => running,
  enable => true,
}
```

### Use Variables

```puppet
$my_message = "Hello from Puppet"
file { 'C:/puppet-test/message.txt':
  ensure  => file,
  content => $my_message,
}
```

## Testing Your Changes

After editing `site.pp`:

1. Deploy the changes:
   ```powershell
   .\deploy-manifest.ps1
   ```

2. Test on one agent first:
   ```powershell
   puppet agent -t --noop
   ```
   (The `--noop` flag shows what would change without actually changing it)

3. Apply for real:
   ```powershell
   puppet agent -t
   ```

## Automatic Execution

By default, agents check in every 30 minutes. To change this, edit the `runinterval` in the agent's `puppet.conf`:

```ini
[main]
    runinterval = 15m  # Check every 15 minutes
```

## Troubleshooting

### "Could not retrieve catalog"
- Check that the Puppet server is running: `docker ps`
- Verify network connectivity: `Test-NetConnection <server-ip> -Port 8140`

### "File not found" errors
- Make sure you deployed the manifest: `.\deploy-manifest.ps1`
- Check the manifest exists in the container:
  ```powershell
  docker exec puppet-server cat /etc/puppetlabs/code/environments/production/manifests/site.pp
  ```

### Changes not applying
- Check for syntax errors: 
  ```powershell
  docker exec puppet-server puppet parser validate /etc/puppetlabs/code/environments/production/manifests/site.pp
  ```

### View server logs
```powershell
docker logs puppet-server -f
```

## Advanced Examples

### Execute a PowerShell Script

```puppet
exec { 'run-custom-script':
  command => 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -File C:/scripts/setup.ps1',
  creates => 'C:/scripts/.setup-complete',
}
```

### Manage Registry Keys

```puppet
registry_key { 'HKLM\Software\MyApp':
  ensure => present,
}

registry_value { 'HKLM\Software\MyApp\Setting':
  ensure => present,
  type   => string,
  data   => 'value',
}
```

### Conditional Logic

```puppet
if $facts['processors']['count'] > 4 {
  notify { 'High Performance System Detected': }
}
```

## Next Steps

1. Customize the node definitions for your actual hostnames
2. Add your specific configuration requirements
3. Create modules for reusable configurations
4. Set up Hiera for data separation
5. Implement environments (dev, staging, production)

## Useful Commands

### On Puppet Server (via Docker)
```powershell
# Validate manifest syntax
docker exec puppet-server puppet parser validate /etc/puppetlabs/code/environments/production/manifests/site.pp

# List signed certificates
docker exec puppet-server puppetserver ca list --all

# View server logs
docker logs puppet-server -f
```

### On Agent Nodes
```powershell
# Test run (no changes)
puppet agent -t --noop

# Apply configuration
puppet agent -t

# See last run report
puppet agent --summarize

# View agent version
puppet --version
```
