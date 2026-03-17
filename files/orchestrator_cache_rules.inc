# Upstream and basic proxy settings
proxy_pass http://localhost:4430;
proxy_read_timeout 120;

proxy_set_header X-SSL-Subject $ssl_client_s_dn;
proxy_set_header X-Client-DN $ssl_client_s_dn;
proxy_set_header X-Client-Verify $ssl_client_verify;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

# ---------- CACHING (Option B) ----------
# Use the HTTP-level cache zone (already defined via proxy_cache_path in http{})
proxy_cache            pe_api_cache;
proxy_cache_lock       on;
proxy_cache_use_stale  error timeout http_500 http_502 http_503 http_504 updating;

# **Override upstream no-store/Expires** (scope limited to these locations)
proxy_ignore_headers   Cache-Control Expires;

# **Do NOT bypass on Authorization** (Option B)
# (We are intentionally allowing caching even when auth is present)
# proxy_no_cache     $http_authorization;      # REMOVE or comment out
# proxy_cache_bypass $http_authorization;      # REMOVE or comment out

# TTLs — tune per endpoint; start small and adjust after observation
proxy_cache_valid      200 5s;
proxy_cache_valid      301 302 1m;

# Keep Set-Cookie from disabling cache **only** if responses aren’t per-user
proxy_ignore_headers   Set-Cookie;

# Cache key: method is usually GET here; include method only if you vary by it
proxy_cache_key        $scheme$host$request_uri;

# Visibility: show HIT/MISS/BYPASS/EXPIRED
add_header X-Proxy-Cache $upstream_cache_status always;