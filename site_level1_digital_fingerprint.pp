# =============================================================================
# site_level1_digital_fingerprint.pp - Level 1: The Digital Fingerprint
# =============================================================================
# Objective:
#   Prove that the Puppet Master and Windows Agent are communicating correctly
#   by enforcing the existence of a specific file with specific content on
#   the agent machine.
#
# Concepts demonstrated:
#   - File resource management
#   - Idempotency: running the agent multiple times produces the same result
#   - Self-healing: Puppet restores deleted or modified files automatically
#   - Resource ordering via the 'require' metaparameter
#
# Self-healing challenge:
#   After Puppet creates C:\PuppetMission\hello.txt, delete the file manually,
#   then run `puppet agent -t` again. Puppet detects the divergence from the
#   declared desired state and recreates the file without any manual steps.
#
# Prerequisites:
#   - Puppet Master running (docker-compose up -d --build)
#   - Windows Agent configured with correct server IP in puppet.conf
#   - Administrator PowerShell session on the Windows Agent
#
# Activation:
#   Copy this file's content into site.pp on the Master, then run:
#     puppet agent -t
# =============================================================================

node default {

  # --------------------------------------------------------------------------
  # Directory resource — C:\PuppetMission
  # Puppet creates this directory if it does not already exist.
  # The 'ensure => directory' attribute distinguishes a directory resource
  # from a regular file resource. This is declared first because the file
  # resource below depends on its existence.
  # --------------------------------------------------------------------------
  file { 'C:/PuppetMission':
    ensure => directory,
  }

  # --------------------------------------------------------------------------
  # File resource — C:\PuppetMission\hello.txt
  # Puppet creates this file and enforces its content on every agent run.
  # The 'require' metaparameter establishes an ordering dependency: Puppet
  # will not attempt to manage this file until the parent directory resource
  # has been applied successfully.
  #
  # If the file is deleted:   Puppet recreates it.
  # If the content is changed: Puppet overwrites it with the declared content.
  # This is the core principle of desired-state configuration management.
  # --------------------------------------------------------------------------
  file { 'C:/PuppetMission/hello.txt':
    ensure  => file,
    content => "Puppet was here at Arnav\n",
    require => File['C:/PuppetMission'],
  }

  # --------------------------------------------------------------------------
  # Notify resource
  # Writes a confirmation message to the agent run log so it is easy to
  # verify which manifest was applied during the catalog run.
  # --------------------------------------------------------------------------
  notify { 'level1_applied':
    message => '[Level 1] Digital Fingerprint manifest applied successfully.',
  }

}
