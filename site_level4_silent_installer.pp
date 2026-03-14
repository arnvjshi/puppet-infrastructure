# =============================================================================
# Level 4: The Silent Installer
# =============================================================================
# Task: Install Notepad++ silently via Chocolatey — no clicking "Next".
# Requirement: The puppetlabs-chocolatey module must be installed on the Master.
#   Run on the Master container:
#     puppet module install puppetlabs-chocolatey
#   Chocolatey itself must also be installed on the Windows Agent first:
#     Set-ExecutionPolicy Bypass -Scope Process -Force
#     [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
#     iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
# Challenge: Uninstall Notepad++ manually, run `puppet agent -t` — Puppet
#            silently reinstalls it.
# =============================================================================

node default {

  include chocolatey

  package { 'notepadplusplus':
    ensure   => installed,
    provider => chocolatey,
  }

  notify { 'level4_applied':
    message => '[Level 4] Silent Installer manifest applied — Notepad++ installed via Chocolatey.',
  }

}
