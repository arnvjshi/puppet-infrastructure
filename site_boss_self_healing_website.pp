# =============================================================================
# Boss Level: The Self-Healing Website
# =============================================================================
# Task:
#   1. Install the IIS Web Server Windows feature.
#   2. Ensure the W3SVC (World Wide Web Publishing) service is always running.
#   3. Deploy a custom index.html — Puppet restores it if tampered with.
#
# Requirement: The puppetlabs-iis module must be installed on the Master.
#   Run on the Master container:
#     puppet module install puppetlabs-iis
#
# Challenge: Manually edit C:\inetpub\wwwroot\index.html to something else,
#            then run `puppet agent -t` — Puppet overwrites it back.
# =============================================================================

node default {

  # ── 1. Install the IIS Web-Server Windows feature ──────────────────────────
  iis_feature { 'Web-Server':
    ensure => present,
  }

  # ── 2. Keep the W3SVC service running at all times ─────────────────────────
  service { 'W3SVC':
    ensure  => running,
    enable  => true,
    require => Iis_feature['Web-Server'],
  }

  # ── 3. Deploy (and protect) the home page ──────────────────────────────────
  file { 'C:/inetpub/wwwroot/index.html':
    ensure  => file,
    content => @("HTML")
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <title>Puppet Self-Healing Site</title>
        <style>
          body { font-family: sans-serif; text-align: center; margin-top: 80px; background: #0d1117; color: #c9d1d9; }
          h1   { color: #58a6ff; font-size: 3rem; }
          p    { font-size: 1.2rem; }
        </style>
      </head>
      <body>
        <h1>Puppet Was Here</h1>
        <p>This page is managed by Puppet. Any change you make will be reverted.</p>
        <p>Deployed by: Arnav</p>
      </body>
      </html>
      | HTML
    require => Iis_feature['Web-Server'],
  }

  notify { 'boss_level_applied':
    message => '[Boss Level] Self-Healing Website manifest applied — IIS installed, W3SVC running, index.html locked.',
  }

}
