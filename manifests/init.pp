#
#
#

class orchestrator_cache {
  # HTTP-level cache definition (auto-included by nginx.conf)
  file { '/etc/puppetlabs/nginx/conf.d/cache_http.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/orchestrator_cache/cache_http.conf',
    require => File['/var/cache/nginx'],
  }

  file { '/var/cache/nginx':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # Location-level snippet
  file { '/etc/puppetlabs/nginx/conf.d/includes/':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # Location-level snippet
  file { '/etc/puppetlabs/nginx/conf.d/includes/orchestrator_cache.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/orchestrator_cache/orchestrator_cache.conf',
    require => File['/etc/puppetlabs/nginx/conf.d/includes/'],
  }

  # Insert include into PE's server block inside proxy.conf
  pe_nginx::directive { 'include orchestrator cache':
    directive_ensure => 'present',
    target           => '/etc/puppetlabs/nginx/conf.d/proxy.conf',
    directive_name   => 'include',
    value            => 'conf.d/includes/orchestrator_cache.conf',
    server_context   => $facts['networking']['fqdn'],
  }
}
