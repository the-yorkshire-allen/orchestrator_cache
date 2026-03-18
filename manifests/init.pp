# @summary
# Configure PE NGINX server‑context caching rules for Orchestrator APIs and inject
# them into the console vhost using `pe_nginx::directive`. This class renders the
# rules include from EPP so TTLs and options are parameterized.
#
# @example Basic usage (defaults)
#   class { 'orchestrator_cache': }
#
# @example Set a 10s TTL for 200 responses and 2m for redirects
#   class { 'orchestrator_cache':
#     cache_ttl_200       => '10s',
#     cache_ttl_redirects => '2m',
#   }
#
# @example Override upstream URL and keep Set-Cookie ignored
#   class { 'orchestrator_cache':
#     upstream_url      => 'http://localhost:4430',
#     ignore_set_cookie => true,
#   }
#
# @example Target a specific vhost name if it differs from the node FQDN
#   class { 'orchestrator_cache':
#     server_name_override => 'pesite2.local',
#   }
#
# @param cache_ttl_200
# TTL applied to successful (HTTP 200) responses in the proxy cache.
# Accepts NGINX time format strings (e.g. '5s', '10s', '1m', '2h').
#
# @param cache_ttl_redirects
# TTL applied to HTTP 301/302 responses (redirects). Typically longer than 200 TTLs.
#
# @param upstream_url
# The upstream URL used by `proxy_pass` for console‑services (default: 'http://localhost:4430').
#
# @param ignore_set_cookie
# If true, `proxy_ignore_headers Set-Cookie;` is emitted so cookies do not disable caching.
# Set false if responses could be user‑specific.
#
# @param server_name_override
# Optional vhost name to target when injecting the server‑level include into
# `/etc/puppetlabs/nginx/conf.d/proxy.conf`. If undef, `$facts['networking']['fqdn']` is used.
class orchestrator_cache (
  String                       $cache_ttl_200        = '5s',  # e.g., '5s', '10s', '2m'
  String                       $cache_ttl_redirects  = '1m',  # e.g., '1m', '5m'
  String                       $upstream_url          = 'http://localhost:4430',
  Boolean                      $ignore_set_cookie     = true,
  Optional[String]             $server_name_override  = undef,  # if vhost name differs from $facts['networking']['fqdn']
) {
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
  file { '/etc/puppetlabs/nginx/includes/':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # Location-level snippet
  file { '/etc/puppetlabs/nginx/includes/orchestrator_cache.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/orchestrator_cache/orchestrator_cache.conf',
    require => [File['/etc/puppetlabs/nginx/includes/'],File['/etc/puppetlabs/nginx/includes/orchestrator_cache_rules.inc'],],
  }

  # Shared cache rules
  file { '/etc/puppetlabs/nginx/includes/orchestrator_cache_rules.inc':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('orchestrator_cache/orchestrator_cache_rules.epp', {
        'ttl_200'           => $cache_ttl_200,
        'ttl_redirects'     => $cache_ttl_redirects,
        'upstream'          => $upstream_url,
        'ignore_set_cookie' => $ignore_set_cookie,
    }),
    require => File['/etc/puppetlabs/nginx/includes'],
  }

  # Insert include into PE's server block inside proxy.conf
  pe_nginx::directive { 'include orchestrator cache':
    directive_ensure => 'present',
    target           => '/etc/puppetlabs/nginx/conf.d/proxy.conf',
    directive_name   => 'include',
    value            => 'includes/orchestrator_cache.conf',
    server_context   => $server_name_override ? {
      undef   => $facts['networking']['fqdn'],
      default => $server_name_override,
    },
    require          => File['/etc/puppetlabs/nginx/includes/orchestrator_cache.conf'],
  }
}
