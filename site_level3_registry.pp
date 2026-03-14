# =============================================================================
# Level 3: Secret Agent Registry
# =============================================================================
# Task: Create HKLM\Software\PuppetMaster with a value MissionStatus = "Success".
# Requirement: The puppetlabs-registry module must be installed on the Master.
#   Run on the Master container:
#     puppet module install puppetlabs-registry
# Challenge: Open regedit.exe, navigate to HKLM\Software\PuppetMaster,
#            delete the value, then run `puppet agent -t` — Puppet restores it.
# =============================================================================

node default {

  registry_key { 'HKLM\Software\PuppetMaster':
    ensure => present,
  }

  registry_value { 'HKLM\Software\PuppetMaster\MissionStatus':
    ensure  => present,
    type    => string,
    data    => 'Success',
    require => Registry_key['HKLM\Software\PuppetMaster'],
  }

  notify { 'level3_applied':
    message => '[Level 3] Registry manifest applied — MissionStatus = Success.',
  }

}
