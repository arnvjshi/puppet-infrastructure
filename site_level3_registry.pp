# =============================================================================
# site_level3_registry.pp - Level 3: Secret Agent Registry
# =============================================================================
# Objective:
#   Demonstrate Windows Registry management by creating a custom registry key
#   and enforcing a specific string value beneath it.
#
# Concepts demonstrated:
#   - registry_key and registry_value resource types (puppetlabs-registry module)
#   - Parent-child resource relationships and ordering via 'require'
#   - Desired-state enforcement on the Windows Registry
#   - The Registry as a configuration store for application and system settings
#
# Module requirement:
#   The puppetlabs-registry Forge module must be installed on the Puppet Master
#   before this manifest is applied. Install it by running the following command
#   inside the running Master container:
#
#     docker exec puppet-server puppet module install puppetlabs-registry
#
# Registry path explained:
#   HKLM  = HKEY_LOCAL_MACHINE (machine-wide, not user-specific)
#   Software\PuppetMaster  = Custom key created by this manifest
#   MissionStatus          = String value set to 'Success'
#
# Self-healing challenge:
#   Open regedit.exe, navigate to HKLM\Software\PuppetMaster, and delete the
#   'MissionStatus' value (or the entire key). Run `puppet agent -t`. Puppet
#   detects the missing key/value and recreates both exactly as declared.
#
# Activation:
#   Copy this file's content into site.pp on the Master, then run:
#     puppet agent -t
# =============================================================================

node default {

  # --------------------------------------------------------------------------
  # Registry key resource — HKLM\Software\PuppetMaster
  # Creates the parent registry key if it does not already exist.
  # This must be declared before the registry_value resource because the value
  # cannot exist without its parent key. The 'require' on the value below
  # enforces this ordering constraint in the Puppet catalog.
  # --------------------------------------------------------------------------
  registry_key { 'HKLM\Software\PuppetMaster':
    ensure => present,
  }

  # --------------------------------------------------------------------------
  # Registry value resource — HKLM\Software\PuppetMaster\MissionStatus
  # Creates (or enforces) a REG_SZ (string) value named 'MissionStatus'
  # with the data set to 'Success'.
  #
  # Attributes:
  #   ensure => present  : The value must exist; Puppet creates it if missing.
  #   type   => string   : Maps to the REG_SZ Windows Registry data type.
  #   data   => 'Success': The enforced string content of the value.
  #   require            : Ensures the parent key is applied first.
  # --------------------------------------------------------------------------
  registry_value { 'HKLM\Software\PuppetMaster\MissionStatus':
    ensure  => present,
    type    => string,
    data    => 'Success',
    require => Registry_key['HKLM\Software\PuppetMaster'],
  }

  # --------------------------------------------------------------------------
  # Notify resource
  # Confirms in the agent run output that the registry manifest was applied.
  # --------------------------------------------------------------------------
  notify { 'level3_applied':
    message => '[Level 3] Registry manifest applied — HKLM\Software\PuppetMaster\MissionStatus = Success.',
  }

}
