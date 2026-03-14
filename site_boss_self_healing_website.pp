# =============================================================================
# site_boss_self_healing_website.pp - Boss Level: The Self-Healing Website
# =============================================================================
# Objective:
#   Deploy a fully managed IIS web server on the Windows Agent where every
#   component — the Windows feature, the service state, and the website
#   content — is enforced by Puppet and automatically restored if tampered with.
#
# Concepts demonstrated:
#   - Composite desired-state management across multiple resource types
#   - Resource ordering chains: feature -> service -> file (dependency graph)
#   - The puppetlabs-iis module for Windows feature and site management
#   - Content-level self-healing: Puppet checksums and re-enforces file content
#   - Infrastructure as Code: the entire web server is defined in one manifest
#
# Resource dependency chain:
#   iis_feature['Web-Server']
#     |__ service['W3SVC']         (requires IIS feature to be installed first)
#     |__ file['index.html']       (requires IIS feature to be installed first)
#
# Module requirement:
#   The puppetlabs-iis Forge module must be installed on the Puppet Master:
#     docker exec puppet-server puppet module install puppetlabs-iis
#
# Self-healing challenge:
#   Open C:\inetpub\wwwroot\index.html in a text editor and change its content.
#   Run `puppet agent -t`. Puppet checksums the file, detects the content drift,
#   and overwrites the file with the exact declared content.
#   Similarly, if the W3SVC service is stopped manually, Puppet restarts it.
#
# Verifying the website after deployment:
#   Open a browser on the Windows Agent and navigate to:
#     http://localhost
#   The custom home page declared in this manifest should appear.
#
# Activation:
#   Copy this file's content into site.pp on the Master, then run:
#     puppet agent -t
# =============================================================================

node default {

  # --------------------------------------------------------------------------
  # IIS feature resource — Web-Server
  # Installs the Internet Information Services (IIS) Windows feature using the
  # puppetlabs-iis module. 'Web-Server' is the Windows feature name and maps
  # to the 'IIS-WebServer' component in the Windows Optional Features list.
  #
  # This resource is the root of the dependency chain. All subsequent IIS
  # resources in this manifest declare it as a prerequisite so that Puppet
  # only attempts to configure IIS after it has confirmed the feature is installed.
  # --------------------------------------------------------------------------
  iis_feature { 'Web-Server':
    ensure => present,
  }

  # --------------------------------------------------------------------------
  # Service resource — W3SVC (World Wide Web Publishing Service)
  # Ensures the IIS web server service is running and set to start automatically
  # on system boot.
  #
  # ensure => running  : Puppet starts the service if it is not currently running.
  # enable => true     : Sets the Windows service startup type to Automatic.
  # require            : Puppet will not attempt to manage the service until the
  #                      IIS feature has been successfully installed.
  # --------------------------------------------------------------------------
  service { 'W3SVC':
    ensure  => running,
    enable  => true,
    require => Iis_feature['Web-Server'],
  }

  # --------------------------------------------------------------------------
  # File resource — C:\inetpub\wwwroot\index.html
  # Deploys the website home page and enforces its exact content.
  # C:\inetpub\wwwroot is the default IIS website root directory.
  #
  # Puppet computes a checksum of the file content on every agent run.
  # If the checksum does not match the declared content, Puppet overwrites
  # the file, restoring the desired state. This is content-level self-healing.
  #
  # The heredoc syntax (@("HTML") ... | HTML) is a Puppet multi-line string
  # literal that preserves formatting without requiring escape characters.
  # --------------------------------------------------------------------------
  file { 'C:/inetpub/wwwroot/index.html':
    ensure  => file,
    content => @("HTML"),
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <title>Puppet Self-Healing Site</title>
        <style>
          body {
            font-family: sans-serif;
            text-align: center;
            margin-top: 80px;
            background: #0d1117;
            color: #c9d1d9;
          }
          h1 { color: #58a6ff; font-size: 3rem; }
          p  { font-size: 1.2rem; }
          .badge {
            display: inline-block;
            margin-top: 20px;
            padding: 6px 14px;
            background: #58a6ff;
            color: #0d1117;
            border-radius: 4px;
            font-weight: bold;
          }
        </style>
      </head>
      <body>
        <h1>Puppet Infrastructure</h1>
        <p>This page is managed by Puppet.</p>
        <p>Any manual change to this file will be reverted on the next agent run.</p>
        <div class="badge">Deployed by Arnav</div>
      </body>
      </html>
      | HTML
    require => Iis_feature['Web-Server'],
  }

  # --------------------------------------------------------------------------
  # Notify resource
  # Confirms in the agent run output that all Boss Level resources were applied.
  # --------------------------------------------------------------------------
  notify { 'boss_level_applied':
    message => '[Boss Level] Self-Healing Website applied — IIS installed, W3SVC running, index.html enforced.',
  }

}
