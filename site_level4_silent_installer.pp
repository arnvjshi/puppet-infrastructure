# =============================================================================
# site_level4_silent_installer.pp - Level 4: The Silent Installer
# =============================================================================
# Objective:
#   Install Notepad++ on the Windows Agent without any user interaction, using
#   the Chocolatey package manager as a Puppet provider.
#
# Concepts demonstrated:
#   - Package resource management via a third-party provider
#   - The Chocolatey provider: a Windows-native package manager
#   - Separation of concerns: Puppet manages the desired state, Chocolatey
#     handles the low-level download and installation logic
#   - Idempotency: running the manifest again on an already-installed system
#     produces no changes (Puppet detects the package is present and skips it)
#
# Prerequisites on the Puppet Master:
#   The puppetlabs-chocolatey Forge module must be installed:
#     docker exec puppet-server puppet module install puppetlabs-chocolatey
#
# Prerequisites on the Windows Agent:
#   Chocolatey itself must be installed before this manifest is applied.
#   Run the following commands in an Administrator PowerShell session:
#
#     Set-ExecutionPolicy Bypass -Scope Process -Force
#     [System.Net.ServicePointManager]::SecurityProtocol = `
#         [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
#     Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
#         'https://community.chocolatey.org/install.ps1'))
#
# Self-healing challenge:
#   Uninstall Notepad++ manually via Add/Remove Programs (or choco uninstall).
#   Run `puppet agent -t`. Puppet detects the package is absent and silently
#   reinstalls it via Chocolatey without any wizard or user prompt.
#
# Activation:
#   Copy this file's content into site.pp on the Master, then run:
#     puppet agent -t
# =============================================================================

node default {

  # --------------------------------------------------------------------------
  # Include the chocolatey class
  # This line loads the puppetlabs-chocolatey module and configures the
  # Chocolatey provider on the agent. It must appear before any package
  # resource that uses the chocolatey provider.
  # --------------------------------------------------------------------------
  include chocolatey

  # --------------------------------------------------------------------------
  # Package resource — notepadplusplus
  # Declares that Notepad++ must be installed on the agent.
  #
  # Attributes:
  #   ensure   => installed  : The package must be present. Puppet installs
  #                            it if absent; takes no action if already present.
  #   provider => chocolatey : Use Chocolatey to manage this package instead
  #                            of the default Windows package provider.
  #
  # The package name 'notepadplusplus' is the exact Chocolatey community
  # repository package identifier. It can be verified at:
  #   https://community.chocolatey.org/packages/notepadplusplus
  # --------------------------------------------------------------------------
  package { 'notepadplusplus':
    ensure   => installed,
    provider => chocolatey,
  }

  # --------------------------------------------------------------------------
  # Notify resource
  # Confirms in the agent run output that the silent installer manifest ran.
  # --------------------------------------------------------------------------
  notify { 'level4_applied':
    message => '[Level 4] Silent Installer applied — Notepad++ installed via Chocolatey.',
  }

}
