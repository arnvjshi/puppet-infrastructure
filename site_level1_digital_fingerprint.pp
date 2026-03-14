# =============================================================================
# Level 1: The Digital Fingerprint
# =============================================================================
# Task: Create C:\PuppetMission\hello.txt containing a signature message.
# Challenge: Delete the file manually, run `puppet agent -t` again — Puppet
#            will recreate it. This demonstrates idempotent self-healing.
# =============================================================================

node default {

  # Ensure the mission directory exists before creating files inside it
  file { 'C:/PuppetMission':
    ensure => directory,
  }

  file { 'C:/PuppetMission/hello.txt':
    ensure  => file,
    content => "Puppet was here at Arnav\n",
    require => File['C:/PuppetMission'],
  }

  notify { 'level1_applied':
    message => '[Level 1] Digital Fingerprint manifest applied successfully.',
  }

}
