# PowerShell script to deploy the Puppet manifest to the Docker container

Write-Host "Deploying Puppet manifest files to the server..." -ForegroundColor Green

# Create the manifests directory in the container
docker exec puppet-server mkdir -p /etc/puppetlabs/code/environments/production/manifests

# Copy the site.pp manifest
Write-Host "Copying site.pp manifest..." -ForegroundColor Yellow
Get-Content ".\site.pp" | docker exec -i puppet-server bash -c 'cat > /etc/puppetlabs/code/environments/production/manifests/site.pp'

# Set proper permissions
docker exec puppet-server chown -R puppet:puppet /etc/puppetlabs/code

# Verify the files
Write-Host "`nVerifying deployment..." -ForegroundColor Green
Write-Host "`nManifest content:" -ForegroundColor Cyan
docker exec puppet-server cat /etc/puppetlabs/code/environments/production/manifests/site.pp

Write-Host "`n`nDeployment complete!" -ForegroundColor Green
Write-Host "Your agents will receive this configuration on their next run." -ForegroundColor Yellow
Write-Host "`nTo test immediately on an agent, run: puppet agent -t" -ForegroundColor Cyan
