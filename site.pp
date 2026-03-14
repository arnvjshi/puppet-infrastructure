# =============================================================================
# site.pp - Root Node Manifest
# =============================================================================
# This is the entry point for all Puppet catalog compilations.
# The Puppet Master reads this file when an agent node requests a catalog.
#
# The 'node default' block applies to every agent that does not match a more
# specific named node declaration. In this lab environment all challenge
# levels target a single Windows agent, so the default node block is used.
#
# To test a specific challenge level, replace the resource declarations in
# this file with the contents of the relevant site_level*.pp file, then run:
#   puppet agent -t    (Administrator PowerShell on the Windows Agent)
#
# This baseline configuration was used for initial Master-Agent connectivity
# verification before the formal challenge levels were deployed.
# =============================================================================

node default {

  # --------------------------------------------------------------------------
  # Directory resource
  # Puppet ensures C:\puppet-test exists as a directory.
  # All file resources nested inside declare this as a 'require' dependency
  # so Puppet always creates the parent directory before its children.
  # --------------------------------------------------------------------------
  file { 'C:/puppet-test':
    ensure => directory,
  }

  # --------------------------------------------------------------------------
  # Plain-text file resource
  # Creates hello.txt with a static greeting string.
  # If the file is deleted or its contents are modified, the next agent run
  # will restore the exact declared state, demonstrating idempotency.
  # --------------------------------------------------------------------------
  file { 'C:/puppet-test/hello.txt':
    ensure  => file,
    content => "Hello from Puppet\n",
    require => File['C:/puppet-test'],
  }

  # --------------------------------------------------------------------------
  # HTML file resource
  # Puppet enforces the exact content of this file on every catalog run.
  # Any manual edits will be overwritten the next time the agent converges.
  # --------------------------------------------------------------------------
  file { 'C:/puppet-test/index.html':
    ensure  => file,
    content => "<!DOCTYPE html><html><head><title>Puppet Demo</title></head><body><h1>Puppet Infrastructure</h1><p>Managed by Puppet - Arnav</p></body></html>",
    require => File['C:/puppet-test'],
  }

  # --------------------------------------------------------------------------
  # Registry key resource (requires puppetlabs-registry module on the Master)
  # Creates the key HKLM\Software\PuppetMaster as the parent container for
  # the registry value declared below.
  # --------------------------------------------------------------------------
  registry_key { 'HKLM\\Software\\PuppetMaster':
    ensure => present,
  }

  # --------------------------------------------------------------------------
  # Registry value resource
  # Sets the string value 'MissionStatus' under the key created above.
  # The 'require' metaparameter guarantees the key exists before the value
  # is written, enforcing the correct resource ordering in the catalog.
  # --------------------------------------------------------------------------
  registry_value { 'HKLM\\Software\\PuppetMaster\\MissionStatus':
    ensure  => present,
    type    => string,
    data    => 'Success',
    require => Registry_key['HKLM\\Software\\PuppetMaster'],
  }

  # --------------------------------------------------------------------------
  # Notify resource
  # Emits a human-readable message in the agent run output.
  # Used to confirm which manifest block was applied during a catalog run.
  # --------------------------------------------------------------------------
  notify { 'base_manifest_applied':
    message => '[Base] Root manifest applied successfully to the default node.',
  }

}
