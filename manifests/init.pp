#
#
#

class orchestrator_cache {
  # HTTP-level cache definition (auto-included by nginx.conf)
  file { '/etc/puppetlabs/nginx/conf.d/cache_http.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/orchestrator_cache/cache_http.conf',
  }

  # Location-level snippet
  file { '/etc/puppetlabs/nginx/conf.d/orchestrator_cache.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/orchestrator_cache/orchestrator_cache.conf',
  }

  # Insert include into PE's server block inside proxy.conf
  pe_nginx::directive { 'include orchestrator cache':
    directive_ensure => 'present',
    target           => '/etc/puppetlabs/nginx/conf.d/proxy.conf',
    directive_name   => 'include',
    value            => 'orchestrator_cache.conf',
    server_context   => $facts['networking']['fqdn'],
  }
}
