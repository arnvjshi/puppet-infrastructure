# Puppet Infrastructure — Windows Agent Challenge

## Overview

This repository contains a fully functional Puppet Master deployment (via Docker) and a structured series of Puppet manifests that demonstrate core configuration management principles on a Windows agent. Each manifest is self-contained and maps to a specific challenge level, showcasing idempotency, desired-state enforcement, facts-driven configuration, and self-healing infrastructure.

The Puppet Master runs inside a Docker container. The Windows machine acts as the Puppet Agent. All state is declared in code; no manual configuration of the agent machine is required after initial bootstrapping.

---

## Repository Structure

```
puppet server/
├── docker-compose.yml                  # Defines the Puppet Master container
├── Dockerfile                          # Custom Puppet Server image
├── puppet.conf                         # Puppet Master configuration
├── autosign.conf                       # Automatic certificate signing rules
├── site.pp                             # Root node manifest (active deployment)
├── site_level1_digital_fingerprint.pp  # Level 1 — File creation and idempotency
├── site_level2_service_lock.pp         # Level 2 — Service enforcement
├── site_level3_registry.pp             # Level 3 — Windows Registry management
├── site_level4_silent_installer.pp     # Level 4 — Silent software installation
├── site_level5_identity_report.pp      # Level 5 — Facts-driven configuration
├── site_boss_self_healing_website.pp   # Boss Level — IIS self-healing web server
├── deploy-manifest.ps1                 # PowerShell helper to deploy manifests
├── MANIFEST-GUIDE.md                   # Manifest authoring reference
└── .gitignore
```

---

## Architecture

```
+---------------------+          Port 8140 (TLS)         +---------------------+
|   Puppet Master     |  <----------------------------->  |   Windows Agent     |
|  (Docker Container) |                                   |  (Local Machine)    |
|                     |   1. Agent requests catalog       |                     |
|  Reads: site.pp     |   2. Master compiles & sends      |  Runs: puppet agent |
|  Signs certificates |   3. Agent enforces desired state |  Applies resources  |
+---------------------+                                   +---------------------+
```

The Master is the single source of truth. The Agent periodically converges its local state to match whatever is declared in the manifest.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Docker Desktop | Must be running before starting the Master |
| Docker Compose | Bundled with Docker Desktop on Windows |
| Puppet Agent | Installed on the Windows machine |
| Administrator privileges | Required on the Windows Agent for all challenge levels |
| Internet access (Agent) | Required for Level 4 (Chocolatey) and Boss Level (IIS) |

---

## Initial Setup

### Step 1 — Start the Puppet Master

From the `puppet server` directory, build and start the container:

```bash
docker-compose up -d --build
```

Verify the server started successfully:

```bash
docker-compose logs -f puppet-server
```

Wait until the logs confirm Puppet Server is running and accepting connections on port 8140.

### Step 2 — Find the Master's IP Address

Run the following on the machine hosting Docker:

```powershell
ipconfig
```

Note the IP address of the network adapter that the Windows Agent can reach (typically the Ethernet or Wi-Fi adapter, not the Docker NAT adapter).

Alternatively, retrieve the container's internal IP:

```bash
docker inspect -f "{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}" puppet-server
```

### Step 3 — Configure the Windows Agent

On the Windows machine, open `C:\ProgramData\PuppetLabs\puppet\etc\puppet.conf` and ensure the following is present:

```ini
[main]
    server   = <PUPPET_MASTER_IP>
    certname = windows-agent
    runinterval = 30m

[agent]
    server = <PUPPET_MASTER_IP>
```

Replace `<PUPPET_MASTER_IP>` with the IP address found in Step 2.

### Step 4 — Add a Hosts Entry (if DNS is unavailable)

On the Windows Agent, add the following line to `C:\Windows\System32\drivers\etc\hosts`:

```
<PUPPET_MASTER_IP>    puppet puppet-server
```

This allows the agent to resolve the master hostname without a DNS server.

### Step 5 — Register the Agent

Open an **Administrator PowerShell** window on the Windows machine and run:

```powershell
puppet agent -t
```

On the first run the agent will request a certificate. Because `autosign.conf` is configured to sign all requests automatically, the certificate is signed immediately and the first catalog is applied.

---

## Certificate Management

All commands are executed from the host machine against the running container.

List all known certificates (signed and pending):

```bash
docker exec puppet-server puppetserver ca list --all
```

Manually sign a pending certificate:

```bash
docker exec puppet-server puppetserver ca sign --certname <certname>
```

Revoke and clean a certificate:

```bash
docker exec puppet-server puppetserver ca clean --certname <certname>
```

---

## Required Puppet Modules

Some challenge levels depend on third-party Puppet modules. Install them inside the running Master container before applying the corresponding manifest.

```bash
# Level 3 — Windows Registry management
docker exec puppet-server puppet module install puppetlabs-registry

# Level 4 — Chocolatey package provider
docker exec puppet-server puppet module install puppetlabs-chocolatey

# Boss Level — IIS web server management
docker exec puppet-server puppet module install puppetlabs-iis
```

For Level 4, Chocolatey must also be installed on the Windows Agent before the manifest is applied. Run the following in an Administrator PowerShell session on the Agent:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = `
    [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
    'https://community.chocolatey.org/install.ps1'))
```

---

## Challenge Levels

To activate a level, copy the contents of the corresponding `.pp` file into `site.pp` on the Master, then run `puppet agent -t` on the Windows Agent.

Alternatively, use the included PowerShell helper:

```powershell
.\deploy-manifest.ps1 -ManifestFile site_level1_digital_fingerprint.pp
```

### Level 1 — The Digital Fingerprint (`site_level1_digital_fingerprint.pp`)

**Concept:** File resource management and idempotency.

Creates the directory `C:\PuppetMission` and the file `C:\PuppetMission\hello.txt` containing a static signature string.

**Self-healing demonstration:** Delete the file manually, then run `puppet agent -t`. Puppet detects the drift from the desired state and recreates the file without any additional intervention.

### Level 2 — The Service Lock (`site_level2_service_lock.pp`)

**Concept:** Service state enforcement.

Ensures the Windows Print Spooler service (`Spooler`) is always stopped and disabled. This simulates a security hardening policy where certain services must never run.

**Self-healing demonstration:** Start the Spooler service manually via `services.msc`, then run `puppet agent -t`. Puppet stops and disables it again, demonstrating that the desired state always wins.

### Level 3 — Secret Agent Registry (`site_level3_registry.pp`)

**Concept:** Windows Registry management via the `puppetlabs-registry` module.

Creates the registry key `HKLM\Software\PuppetMaster` and sets the string value `MissionStatus` to `Success`.

**Self-healing demonstration:** Delete the value in `regedit.exe`, then run `puppet agent -t`. Puppet recreates the key and value exactly as declared.

**Prerequisite:** `puppet module install puppetlabs-registry` (see above).

### Level 4 — The Silent Installer (`site_level4_silent_installer.pp`)

**Concept:** Package management via the Chocolatey provider.

Installs Notepad++ on the Windows Agent without any user interaction, using the `chocolatey` package provider. No installer wizard, no clicking "Next".

**Self-healing demonstration:** Uninstall Notepad++ manually via Add/Remove Programs, then run `puppet agent -t`. Puppet silently reinstalls it.

**Prerequisites:** `puppetlabs-chocolatey` module on the Master, and Chocolatey installed on the Agent (see above).

### Level 5 — The Identity Report (`site_level5_identity_report.pp`)

**Concept:** Facts-driven dynamic configuration.

Creates `C:\PuppetMission\spec_report.txt` whose content is populated at runtime using Puppet Facts — built-in variables that describe the agent's hardware and operating system. The manifest code is identical on every machine, but the output file is unique per agent because the facts differ.

Facts used:
- `$facts['os']['name']` — Operating system name
- `$facts['os']['release']['full']` — Full OS version string
- `$facts['memory']['system']['total']` — Total system RAM

### Boss Level — The Self-Healing Website (`site_boss_self_healing_website.pp`)

**Concept:** Composite desired-state enforcement across features, services, and file content.

Performs three interdependent tasks in the correct dependency order:
1. Installs the Windows IIS `Web-Server` feature.
2. Ensures the `W3SVC` service is running and set to start automatically.
3. Deploys a custom `C:\inetpub\wwwroot\index.html` and enforces its exact content.

**Self-healing demonstration:** Open the HTML file and change its content to anything. Run `puppet agent -t`. Puppet overwrites the file, restoring the declared content exactly.

**Prerequisite:** `puppetlabs-iis` module on the Master (see above).

---

## Running the Agent

All agent runs require an **Administrator PowerShell** session on the Windows machine.

Apply the current catalog immediately (verbose output):

```powershell
puppet agent -t
```

Check the agent's last run summary:

```powershell
puppet agent --configprint lastrunfile
Get-Content (puppet agent --configprint lastrunfile)
```

---

## Stopping and Cleaning Up

Stop the Master container without removing data:

```bash
docker-compose down
```

Stop the Master and delete all persistent volumes (certificates, catalog cache, module data):

```bash
docker-compose down -v
```

---

## Troubleshooting

**Agent cannot connect to the Master**

- Confirm port 8140 is reachable: `Test-NetConnection -ComputerName <MASTER_IP> -Port 8140`
- Ensure Windows Firewall allows inbound connections on port 8140 on the Master host:
  ```powershell
  New-NetFirewallRule -DisplayName "Puppet Master" -Direction Inbound -Port 8140 -Protocol TCP -Action Allow
  ```

**Certificate errors on the Agent**

- Clean the agent's SSL directory: `Remove-Item -Recurse -Force "C:\ProgramData\PuppetLabs\puppet\etc\ssl"`
- On the Master, clean the stale certificate: `docker exec puppet-server puppetserver ca clean --certname <certname>`
- Re-run `puppet agent -t` to generate a new certificate request.

**Module not found errors**

- Confirm the module is installed: `docker exec puppet-server puppet module list`
- If missing, install it as shown in the "Required Puppet Modules" section above.

**Catalog compilation errors**

- View the full server log: `docker-compose logs puppet-server`
- Validate the manifest syntax before applying: `puppet parser validate site.pp`

---

## Security Notes

- `autosign.conf` is set to sign all certificate requests automatically. This is appropriate for a controlled lab environment. In a production environment, disable autosign and implement a policy-based signing workflow.
- No credentials, private keys, or certificates are committed to this repository. The `.gitignore` explicitly excludes all SSL artifacts.
- Registry and service modifications in the challenge levels are scoped to non-critical system resources and are safe to apply in a development or lab setting.

---

## Author

Arnav — Honors Puppet Infrastructure Assignment
