# =============================================================================
# Level 2: The Service Lock
# =============================================================================
# Task: Keep the Print Spooler service (Spooler) permanently disabled & stopped.
# Challenge: Start the service manually via services.msc, then run
#            `puppet agent -t` — Puppet will stop and disable it again.
# =============================================================================

node default {

  service { 'Spooler':
    ensure => stopped,
    enable => false,
  }

  notify { 'level2_applied':
    message => '[Level 2] Service Lock manifest applied — Spooler is stopped and disabled.',
  }

}
