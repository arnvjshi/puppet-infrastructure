# =============================================================================
# site_level5_identity_report.pp - Level 5: The Identity Report (Facts)
# =============================================================================
# Objective:
#   Generate a system specification report file on each agent whose content
#   is dynamically populated at runtime using Puppet Facts. The same manifest
#   code produces different output on different machines automatically.
#
# Concepts demonstrated:
#   - Puppet Facts: built-in variables that describe the agent's environment
#   - Dynamic content generation: the manifest is static; the file content is not
#   - Facts-driven configuration as a foundation for multi-node infrastructure
#   - The 'facter' subsystem: Facter collects system data and exposes it as
#     $facts[...] variables available in every Puppet manifest
#
# Key facts used in this manifest:
#   $facts['os']['name']               - OS family name, e.g. "windows"
#   $facts['os']['release']['full']    - Full OS version, e.g. "10.0.19045"
#   $facts['memory']['system']['total']- Total RAM, e.g. "15.84 GiB"
#
# All available facts for an agent can be viewed by running on the Agent:
#   facter -p
# Or from the Master after the agent has checked in.
#
# Self-healing challenge:
#   Compare the generated spec_report.txt from two different Windows machines
#   running the same manifest. The file content will differ because the facts
#   differ. This demonstrates the value of facts-based dynamic configuration.
#   As with all Puppet-managed files, manually editing the file will cause
#   Puppet to overwrite it on the next agent run.
#
# Activation:
#   Copy this file's content into site.pp on the Master, then run:
#     puppet agent -t
# =============================================================================

node default {

  # --------------------------------------------------------------------------
  # Directory resource — C:\PuppetMission
  # Ensures the parent directory exists before the report file is created.
  # This is the same directory used in Level 1; it is safe to redeclare it
  # here as Puppet handles idempotency for directory resources natively.
  # --------------------------------------------------------------------------
  file { 'C:/PuppetMission':
    ensure => directory,
  }

  # --------------------------------------------------------------------------
  # File resource — C:\PuppetMission\spec_report.txt
  # The 'content' attribute uses Puppet variable interpolation to embed
  # Facter facts directly into the file content at catalog compile time.
  #
  # The Master compiles a unique catalog for each agent using that agent's
  # fact values, so the generated file content is specific to each machine.
  #
  # Interpolated facts:
  #   ${facts['os']['name']}              - OS name
  #   ${facts['os']['release']['full']}   - Full OS version string
  #   ${facts['memory']['system']['total']}- Human-readable total RAM
  # --------------------------------------------------------------------------
  file { 'C:/PuppetMission/spec_report.txt':
    ensure  => file,
    content => "This machine is running ${facts['os']['name']} ${facts['os']['release']['full']} and has ${facts['memory']['system']['total']} of RAM.\n",
    require => File['C:/PuppetMission'],
  }

  # --------------------------------------------------------------------------
  # Notify resource
  # Confirms in the agent run output that the identity report was generated.
  # --------------------------------------------------------------------------
  notify { 'level5_applied':
    message => '[Level 5] Identity Report applied — spec_report.txt populated with system facts.',
  }

}
