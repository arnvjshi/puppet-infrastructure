# =============================================================================
# site_level2_service_lock.pp - Level 2: The Service Lock
# =============================================================================
# Objective:
#   Enforce a security policy that keeps the Windows Print Spooler service
#   permanently stopped and disabled, regardless of manual intervention.
#
# Concepts demonstrated:
#   - Service resource management
#   - Security hardening through declarative policy
#   - Desired-state enforcement: Puppet always wins against manual changes
#   - The difference between 'ensure' (runtime state) and 'enable' (boot state)
#
# Resource attributes explained:
#   ensure => stopped  — The service must not be running at the time of the
#                        catalog run. If it is running, Puppet stops it.
#   enable => false    — The service must be set to 'Disabled' in the Windows
#                        Services startup type. Prevents it from starting on
#                        reboot or being started by other processes.
#
# Self-healing challenge:
#   Open services.msc and manually start the Print Spooler service.
#   Run `puppet agent -t`. Puppet detects the running service, stops it,
#   and sets its startup type back to Disabled.
#
# Security rationale:
#   The Print Spooler service has a well-documented attack surface (PrintNightmare
#   CVE-2021-34527 and related vulnerabilities). Disabling it on machines that
#   do not require printing is a recommended security hardening measure.
#
# Prerequisites:
#   - Puppet Master running and agent registered
#   - Administrator PowerShell on the Windows Agent
#
# Activation:
#   Copy this file's content into site.pp on the Master, then run:
#     puppet agent -t
# =============================================================================

node default {

  # --------------------------------------------------------------------------
  # Service resource — Print Spooler (Spooler)
  # 'Spooler' is the Windows internal service name.  This value must match
  # exactly what appears in the 'Name' column of services.msc or the output
  # of `Get-Service` in PowerShell.
  #
  # ensure => stopped  : Puppet stops the service if it is currently running.
  # enable => false    : Puppet sets the startup type to Disabled, preventing
  #                      the service from starting automatically on next boot.
  # --------------------------------------------------------------------------
  service { 'Spooler':
    ensure => stopped,
    enable => false,
  }

  # --------------------------------------------------------------------------
  # Notify resource
  # Confirms in the agent run output that the service lock policy was applied.
  # --------------------------------------------------------------------------
  notify { 'level2_applied':
    message => '[Level 2] Service Lock applied — Print Spooler is stopped and disabled.',
  }

}
