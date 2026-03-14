node default {

  file { 'C:/puppet-test':
    ensure => directory,
  }

  file { 'C:/puppet-test/hello.txt':
    ensure  => file,
    content => "hello from puppet\n",
    require => File['C:/puppet-test'],
  }

  file { 'C:/puppet-test/index.html':
    ensure  => file,
    content => "<html><head><title>Puppet Demo</title></head><body><h1>Arnav is great</h1><h3>Hello from Puppet</h3><br>try 3</body></html>",
    require => File['C:/puppet-test'],
  }

  exec { 'open_html':
    command => 'cmd /c start C:/puppet-test/index.html',
    path    => ['C:/Windows/System32','C:/Windows'],
    require => File['C:/puppet-test/index.html'],
  }

  registry_key { 'HKLM\\Software\\PuppetMaster':
    ensure => present,
  }

  registry_value { 'HKLM\\Software\\PuppetMaster\\MissionStatus':
    ensure => present,
    type   => string,
    data   => 'Success',
    require => Registry_key['HKLM\\Software\\PuppetMaster'],
  }


  notify { 'hello_manifest_applied':
    message => 'Basic hello manifest applied successfully',
  }

}
