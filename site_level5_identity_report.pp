# =============================================================================
# Level 5: The Identity Report (Facts)
# =============================================================================
# Task: Create C:\PuppetMission\spec_report.txt populated with Puppet Facts
#       so each machine reports its own OS name and RAM size automatically.
# Challenge: The manifest code is identical on every agent, but the file
#            content will differ per machine — that is the power of Facts.
#
# Useful built-in facts used here:
#   $facts['os']['name']              — e.g. "windows"
#   $facts['os']['release']['full']   — e.g. "10.0.19045"
#   $facts['memory']['system']['total'] — e.g. "15.84 GiB"
# =============================================================================

node default {

  # Ensure the mission directory exists
  file { 'C:/PuppetMission':
    ensure => directory,
  }

  file { 'C:/PuppetMission/spec_report.txt':
    ensure  => file,
    content => "This machine is running ${facts['os']['name']} ${facts['os']['release']['full']} and has ${facts['memory']['system']['total']} of RAM.\n",
    require => File['C:/PuppetMission'],
  }

  notify { 'level5_applied':
    message => '[Level 5] Identity Report manifest applied — spec_report.txt written with system facts.',
  }

}
