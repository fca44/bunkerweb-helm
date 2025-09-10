{{/*
Expand the name of the chart.
*/}}
{{- define "bunkerweb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "bunkerweb.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bunkerweb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "bunkerweb.labels" -}}
helm.sh/chart: {{ include "bunkerweb.chart" . }}
{{ include "bunkerweb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bunkerweb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bunkerweb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Expand the namespace of the release.
Allows overriding it for multi-namespace deployments in combined charts.
*/}}
{{- define "bunkerweb.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
UI_HOST setting
*/}}
{{- define "bunkerweb.uiHost" -}}
{{- printf "http://ui-%s.%s.svc.%s:7000" (include "bunkerweb.fullname" .) (include "bunkerweb.namespace" .) .Values.settings.kubernetes.domainName -}}
{{- end -}}

{{/*
DATABASE_URI setting
*/}}
{{- define "bunkerweb.databaseUri" -}}
{{- if .Values.mariadb.enabled -}}
  {{- $user := .Values.mariadb.config.user -}}
  {{- $password := .Values.mariadb.config.password -}}
  {{- $host := printf "mariadb-%s.%s.svc.%s" (include "bunkerweb.fullname" .) (include "bunkerweb.namespace" .) .Values.settings.kubernetes.domainName -}}
  {{- $db := .Values.mariadb.config.database -}}
  {{- printf "mariadb+pymysql://%s:%s@%s:3306/%s" $user $password $host $db -}}
{{- else -}}
  {{- .Values.settings.misc.databaseUri -}}
{{- end -}}
{{- end -}}

{{- /*
REDIS settings
*/}}
{{- define "bunkerweb.redisEnv" -}}
{{- if eq .Values.settings.redis.useRedis "yes" }}
- name: USE_REDIS
  value: "yes"
{{- end }}
{{- if .Values.redis.enabled }}
- name: REDIS_HOST
  {{- if .Values.settings.redis.redisHost }}
  value: "{{ .Values.settings.redis.redisHost }}"
  {{- else }}
  value: "redis-{{ include "bunkerweb.fullname" . }}.{{ include "bunkerweb.namespace" . }}.svc.{{ .Values.settings.kubernetes.domainName }}"
  {{- end }}
- name: REDIS_USERNAME
  value: ""
- name: REDIS_PASSWORD
  {{- if not (empty .Values.settings.existingSecret) }}
  valueFrom:
    secretKeyRef:
      name: "{{ .Values.settings.existingSecret }}"
      key: redis-password
  {{- else }}
  value: "{{ .Values.redis.config.password }}"
  {{- end }}
{{- else }}
- name: REDIS_HOST
  value: "{{ .Values.settings.redis.redisHost }}"
- name: REDIS_USERNAME
    {{- if not (empty .Values.settings.existingSecret) }}
  valueFrom:
    secretKeyRef:
      name: "{{ .Values.settings.existingSecret }}"
      key: redis-username
    {{- else }}
  value: "{{ .Values.settings.redis.redisUsername }}"
    {{- end }}
- name: REDIS_PASSWORD
    {{- if not (empty .Values.settings.existingSecret) }}
  valueFrom:
    secretKeyRef:
      name: "{{ .Values.settings.existingSecret }}"
      key: redis-password
    {{- else }}
  value: "{{ .Values.settings.redis.redisPassword }}"
    {{- end }}
{{- end }}
{{- end }}

{{/*
Generate BunkerWeb feature environment variables
*/}}
{{- define "bunkerweb.featureEnvs" -}}
{{- with .Values.scheduler.features }}
# =============================================================================
# GLOBAL SETTINGS
# =============================================================================
{{- if .global }}
- name: SECURITY_MODE
  value: {{ .global.securityMode | quote }}
- name: DISABLE_DEFAULT_SERVER
  value: {{ .global.disableDefaultServer | quote }}
- name: DISABLE_DEFAULT_SERVER_STRICT_SNI
  value: {{ .global.disableDefaultServerStrictSni | quote }}
{{- end }}

# =============================================================================
# MODSECURITY WAF
# =============================================================================
{{- if .modsecurity }}
- name: USE_MODSECURITY
  value: {{ .modsecurity.useModsecurity | quote }}
- name: USE_MODSECURITY_CRS
  value: {{ .modsecurity.useModsecurityCrs | quote }}
- name: MODSECURITY_CRS_VERSION
  value: {{ .modsecurity.modsecurityCrsVersion | quote }}
- name: MODSECURITY_SEC_RULE_ENGINE
  value: {{ .modsecurity.modsecuritySecRuleEngine | quote }}
- name: USE_MODSECURITY_CRS_PLUGINS
  value: {{ .modsecurity.useModsecurityCrsPlugins | quote }}
{{- if .modsecurity.modsecurityCrsPlugins }}
- name: MODSECURITY_CRS_PLUGINS
  value: {{ .modsecurity.modsecurityCrsPlugins | quote }}
{{- end }}
{{- end }}

# =============================================================================
# ANTIBOT PROTECTION  
# =============================================================================
{{- if .antibot }}
- name: USE_ANTIBOT
  value: {{ .antibot.useAntibot | quote }}
{{- if and .antibot.useAntibot (ne .antibot.useAntibot "no") }}
- name: ANTIBOT_URI
  value: {{ .antibot.antibotUri | quote }}
- name: ANTIBOT_TIME_RESOLVE
  value: {{ .antibot.antibotTimeResolve | quote }}
- name: ANTIBOT_TIME_VALID
  value: {{ .antibot.antibotTimeValid | quote }}
{{- if .antibot.antibotIgnoreIp }}
- name: ANTIBOT_IGNORE_IP
  value: {{ .antibot.antibotIgnoreIp | quote }}
{{- end }}
{{- if .antibot.antibotIgnoreUri }}
- name: ANTIBOT_IGNORE_URI
  value: {{ .antibot.antibotIgnoreUri | quote }}
{{- end }}
{{- end }}
{{- end }}

# =============================================================================
# RATE LIMITING
# =============================================================================
{{- if .rateLimit }}
- name: USE_LIMIT_REQ
  value: {{ .rateLimit.useLimitReq | quote }}
{{- if and .rateLimit.useLimitReq (eq .rateLimit.useLimitReq "yes") }}
- name: LIMIT_REQ_RATE
  value: {{ .rateLimit.limitReqRate | quote }}
- name: LIMIT_REQ_URL
  value: {{ .rateLimit.limitReqUrl | quote }}
{{- end }}
- name: USE_LIMIT_CONN
  value: {{ .rateLimit.useLimitConn | quote }}
{{- if and .rateLimit.useLimitConn (eq .rateLimit.useLimitConn "yes") }}
- name: LIMIT_CONN_MAX_HTTP1
  value: {{ .rateLimit.limitConnMaxHttp1 | quote }}
- name: LIMIT_CONN_MAX_HTTP2
  value: {{ .rateLimit.limitConnMaxHttp2 | quote }}
- name: LIMIT_CONN_MAX_HTTP3
  value: {{ .rateLimit.limitConnMaxHttp3 | quote }}
{{- end }}

# =============================================================================
# BLACKLIST/WHITELIST
# =============================================================================
{{- if .blacklist }}
- name: USE_BLACKLIST
  value: {{ .blacklist.useBlacklist | quote }}
{{- if and .blacklist.useBlacklist (eq .blacklist.useBlacklist "yes") }}
{{- if .blacklist.blacklistCommunityLists }}
- name: BLACKLIST_COMMUNITY_LISTS
  value: {{ .blacklist.blacklistCommunityLists | quote }}
{{- end }}
{{- if .blacklist.blacklistIp }}
- name: BLACKLIST_IP
  value: {{ .blacklist.blacklistIp | quote }}
{{- end }}
{{- if .blacklist.blacklistIpUrls }}
- name: BLACKLIST_IP_URLS
  value: {{ .blacklist.blacklistIpUrls | quote }}
{{- end }}
{{- end }}
{{- end }}

{{- if .whitelist }}
- name: USE_WHITELIST
  value: {{ .whitelist.useWhitelist | quote }}
{{- if and .whitelist.useWhitelist (eq .whitelist.useWhitelist "yes") }}
{{- if .whitelist.whitelistIp }}
- name: WHITELIST_IP
  value: {{ .whitelist.whitelistIp | quote }}
{{- end }}
{{- if .whitelist.whitelistIpUrls }}
- name: WHITELIST_IP_URLS
  value: {{ .whitelist.whitelistIpUrls | quote }}
{{- end }}
{{- end }}

# =============================================================================
# COUNTRY BLOCKING
# =============================================================================
{{- if .geoBlocking }}
{{- if .geoBlocking.whitelistCountry }}
- name: WHITELIST_COUNTRY
  value: {{ .geoBlocking.whitelistCountry | quote }}
{{- end }}
{{- if .geoBlocking.blacklistCountry }}
- name: BLACKLIST_COUNTRY
  value: {{ .geoBlocking.blacklistCountry | quote }}
{{- end }}
{{- end }}

# =============================================================================
# BAD BEHAVIOR DETECTION
# =============================================================================
{{- if .badBehavior }}
- name: USE_BAD_BEHAVIOR
  value: {{ .badBehavior.useBadBehavior | quote }}
{{- if and .badBehavior.useBadBehavior (eq .badBehavior.useBadBehavior "yes") }}
- name: BAD_BEHAVIOR_STATUS_CODES
  value: {{ .badBehavior.badBehaviorStatusCodes | quote }}
- name: BAD_BEHAVIOR_THRESHOLD
  value: {{ .badBehavior.badBehaviorThreshold | quote }}
- name: BAD_BEHAVIOR_COUNT_TIME
  value: {{ .badBehavior.badBehaviorCountTime | quote }}
- name: BAD_BEHAVIOR_BAN_TIME
  value: {{ .badBehavior.badBehaviorBanTime | quote }}
{{- end }}
{{- end }}

# =============================================================================
# SSL/TLS CONFIGURATION
# =============================================================================
{{- if .ssl }}
- name: LISTEN_HTTPS
  value: {{ .ssl.listenHttps | quote }}
{{- if and .ssl.listenHttps (eq .ssl.listenHttps "yes") }}
- name: SSL_PROTOCOLS
  value: {{ .ssl.sslProtocols | quote }}
- name: SSL_CIPHERS_LEVEL
  value: {{ .ssl.sslCiphersLevel | quote }}
- name: AUTO_REDIRECT_HTTP_TO_HTTPS
  value: {{ .ssl.autoRedirectHttpToHttps | quote }}
{{- end }}
{{- end }}

# Let's Encrypt configuration
{{- if .letsEncrypt }}
- name: AUTO_LETS_ENCRYPT
  value: {{ .letsEncrypt.autoLetsEncrypt | quote }}
{{- if and .letsEncrypt.autoLetsEncrypt (eq .letsEncrypt.autoLetsEncrypt "yes") }}
{{- if .letsEncrypt.emailLetsEncrypt }}
- name: EMAIL_LETS_ENCRYPT
  value: {{ .letsEncrypt.emailLetsEncrypt | quote }}
{{- end }}
- name: LETS_ENCRYPT_CHALLENGE
  value: {{ .letsEncrypt.letsEncryptChallenge | quote }}
{{- if .letsEncrypt.letsEncryptDnsProvider }}
- name: LETS_ENCRYPT_DNS_PROVIDER
  value: {{ .letsEncrypt.letsEncryptDnsProvider | quote }}
{{- end }}
- name: USE_LETS_ENCRYPT_WILDCARD
  value: {{ .letsEncrypt.useLetsEncryptWildcard | quote }}
{{- end }}
{{- end }}

# Custom SSL certificate
{{- if .customSsl }}
- name: USE_CUSTOM_SSL
  value: {{ .customSsl.useCustomSsl | quote }}
{{- if and .customSsl.useCustomSsl (eq .customSsl.useCustomSsl "yes") }}
- name: CUSTOM_SSL_CERT_PRIORITY
  value: {{ .customSsl.customSslCertPriority | quote }}
{{- if .customSsl.customSslCert }}
- name: CUSTOM_SSL_CERT
  value: {{ .customSsl.customSslCert | quote }}
{{- end }}
{{- if .customSsl.customSslKey }}
- name: CUSTOM_SSL_KEY
  value: {{ .customSsl.customSslKey | quote }}
{{- end }}
{{- end }}
{{- end }}


# =============================================================================
# COMPRESSION
# =============================================================================
{{- if .compression }}
- name: USE_GZIP
  value: {{ .compression.useGzip | quote }}
{{- if and .compression.useGzip (eq .compression.useGzip "yes") }}
- name: GZIP_COMP_LEVEL
  value: {{ .compression.gzipCompLevel | quote }}
- name: GZIP_MIN_LENGTH
  value: {{ .compression.gzipMinLength | quote }}
{{- end }}
{{- end }}


- name: USE_BROTLI
  value: {{ .compression.useBrotli | quote }}
{{- if and .compression.useBrotli (eq .compression.useBrotli "yes") }}
- name: BROTLI_COMP_LEVEL
  value: {{ .compression.brotliCompLevel | quote }}
{{- end }}

# =============================================================================
# CLIENT CACHING
# =============================================================================
- name: USE_CLIENT_CACHE
  value: {{ .clientCache.useClientCache | quote }}
{{- if eq .clientCache.useClientCache "yes" }}
- name: CLIENT_CACHE_EXTENSIONS
  value: {{ .clientCache.clientCacheExtensions | quote }}
- name: CLIENT_CACHE_CONTROL
  value: {{ .clientCache.clientCacheControl | quote }}
- name: CLIENT_CACHE_ETAG
  value: {{ .clientCache.clientCacheEtag | quote }}
{{- end }}

# =============================================================================
# REVERSE PROXY
# =============================================================================
- name: USE_REVERSE_PROXY
  value: {{ .reverseProxy.useReverseProxy | quote }}
{{- if eq .reverseProxy.useReverseProxy "yes" }}
{{- if .reverseProxy.reverseProxyHost }}
- name: REVERSE_PROXY_HOST
  value: {{ .reverseProxy.reverseProxyHost | quote }}
{{- end }}
- name: REVERSE_PROXY_URL
  value: {{ .reverseProxy.reverseProxyUrl | quote }}
- name: REVERSE_PROXY_CONNECT_TIMEOUT
  value: {{ .reverseProxy.reverseProxyConnectTimeout | quote }}
- name: REVERSE_PROXY_SEND_TIMEOUT
  value: {{ .reverseProxy.reverseProxySendTimeout | quote }}
- name: REVERSE_PROXY_READ_TIMEOUT
  value: {{ .reverseProxy.reverseProxyReadTimeout | quote }}
{{- end }}

# =============================================================================
# REAL IP DETECTION
# =============================================================================
- name: USE_REAL_IP
  value: {{ .realIp.useRealIp | quote }}
{{- if eq .realIp.useRealIp "yes" }}
{{- if .realIp.realIpFrom }}
- name: REAL_IP_FROM
  value: {{ .realIp.realIpFrom | quote }}
{{- end }}
- name: REAL_IP_HEADER
  value: {{ .realIp.realIpHeader | quote }}
- name: REAL_IP_RECURSIVE
  value: {{ .realIp.realIpRecursive | quote }}
- name: USE_PROXY_PROTOCOL
  value: {{ .realIp.useProxyProtocol | quote }}
{{- end }}

# =============================================================================
# SECURITY HEADERS
# =============================================================================
{{- if .headers.strictTransportSecurity }}
- name: STRICT_TRANSPORT_SECURITY
  value: {{ .headers.strictTransportSecurity | quote }}
{{- end }}
{{- if .headers.contentSecurityPolicy }}
- name: CONTENT_SECURITY_POLICY
  value: {{ .headers.contentSecurityPolicy | quote }}
{{- end }}
- name: CONTENT_SECURITY_POLICY_REPORT_ONLY
  value: {{ .headers.contentSecurityPolicyReportOnly | quote }}
{{- if .headers.xFrameOptions }}
- name: X_FRAME_OPTIONS
  value: {{ .headers.xFrameOptions | quote }}
{{- end }}
{{- if .headers.xContentTypeOptions }}
- name: X_CONTENT_TYPE_OPTIONS
  value: {{ .headers.xContentTypeOptions | quote }}
{{- end }}
{{- if .headers.referrerPolicy }}
- name: REFERRER_POLICY
  value: {{ .headers.referrerPolicy | quote }}
{{- end }}
{{- if .headers.removeHeaders }}
- name: REMOVE_HEADERS
  value: {{ .headers.removeHeaders | quote }}
{{- end }}
{{- if .headers.customHeader }}
- name: CUSTOM_HEADER
  value: {{ .headers.customHeader | quote }}
{{- end }}

# =============================================================================
# CORS CONFIGURATION
# =============================================================================
- name: USE_CORS
  value: {{ .cors.useCors | quote }}
{{- if eq .cors.useCors "yes" }}
- name: CORS_ALLOW_ORIGIN
  value: {{ .cors.corsAllowOrigin | quote }}
- name: CORS_ALLOW_METHODS
  value: {{ .cors.corsAllowMethods | quote }}
- name: CORS_ALLOW_HEADERS
  value: {{ .cors.corsAllowHeaders | quote }}
- name: CORS_ALLOW_CREDENTIALS
  value: {{ .cors.corsAllowCredentials | quote }}
{{- end }}

# =============================================================================
# DNSBL CHECKING
# =============================================================================
- name: USE_DNSBL
  value: {{ .dnsbl.useDnsbl | quote }}
{{- if eq .dnsbl.useDnsbl "yes" }}
- name: DNSBL_LIST
  value: {{ .dnsbl.dnsblList | quote }}
{{- end }}

# =============================================================================
# BUNKERNET THREAT INTELLIGENCE
# =============================================================================
- name: USE_BUNKERNET
  value: {{ .bunkerNet.useBunkernet | quote }}
- name: BUNKERNET_SERVER
  value: {{ .bunkerNet.bunkernetServer | quote }}

# =============================================================================
# SESSION MANAGEMENT
# =============================================================================
{{- if .sessions.sessionsSecret }}
- name: SESSIONS_SECRET
  value: {{ .sessions.sessionsSecret | quote }}
{{- end }}
- name: SESSIONS_NAME
  value: {{ .sessions.sessionsName | quote }}
- name: SESSIONS_IDLING_TIMEOUT
  value: {{ .sessions.sessionsIdlingTimeout | quote }}
- name: SESSIONS_ROLLING_TIMEOUT
  value: {{ .sessions.sessionsRollingTimeout | quote }}
- name: SESSIONS_ABSOLUTE_TIMEOUT
  value: {{ .sessions.sessionsAbsoluteTimeout | quote }}
- name: SESSIONS_CHECK_IP
  value: {{ .sessions.sessionsCheckIp | quote }}
- name: SESSIONS_CHECK_USER_AGENT
  value: {{ .sessions.sessionsCheckUserAgent | quote }}

# =============================================================================
# METRICS AND MONITORING
# =============================================================================
- name: USE_METRICS
  value: {{ .metrics.useMetrics | quote }}
{{- if eq .metrics.useMetrics "yes" }}
- name: METRICS_MEMORY_SIZE
  value: {{ .metrics.metricsMemorySize | quote }}
- name: METRICS_MAX_BLOCKED_REQUESTS
  value: {{ .metrics.metricsMaxBlockedRequests | quote }}
- name: METRICS_SAVE_TO_REDIS
  value: {{ .metrics.metricsSaveToRedis | quote }}
{{- end }}

# =============================================================================
# AUTH BASIC
# =============================================================================
- name: USE_AUTH_BASIC
  value: {{ .authBasic.useAuthBasic | quote }}
{{- if eq .authBasic.useAuthBasic "yes" }}
- name: AUTH_BASIC_LOCATION
  value: {{ .authBasic.authBasicLocation | quote }}
{{- if .authBasic.authBasicUser }}
- name: AUTH_BASIC_USER
  value: {{ .authBasic.authBasicUser | quote }}
{{- end }}
{{- if .authBasic.authBasicPassword }}
- name: AUTH_BASIC_PASSWORD
  value: {{ .authBasic.authBasicPassword | quote }}
{{- end }}
- name: AUTH_BASIC_TEXT
  value: {{ .authBasic.authBasicText | quote }}
{{- end }}

# =============================================================================
# REDIRECTS
# =============================================================================
{{- if .redirect.redirectFrom }}
- name: REDIRECT_FROM
  value: {{ .redirect.redirectFrom | quote }}
{{- end }}
{{- if .redirect.redirectTo }}
- name: REDIRECT_TO
  value: {{ .redirect.redirectTo | quote }}
- name: REDIRECT_TO_REQUEST_URI
  value: {{ .redirect.redirectToRequestUri | quote }}
- name: REDIRECT_TO_STATUS_CODE
  value: {{ .redirect.redirectToStatusCode | quote }}
{{- end }}

# =============================================================================
# ERROR PAGES
# =============================================================================
{{- if .errors.errors }}
- name: ERRORS
  value: {{ .errors.errors | quote }}
{{- end }}
- name: INTERCEPTED_ERROR_CODES
  value: {{ .errors.interceptedErrorCodes | quote }}

# =============================================================================
# HTML INJECTION
# =============================================================================
{{- if .htmlInjection.injectHead }}
- name: INJECT_HEAD
  value: {{ .htmlInjection.injectHead | quote }}
{{- end }}
{{- if .htmlInjection.injectBody }}
- name: INJECT_BODY
  value: {{ .htmlInjection.injectBody | quote }}
{{- end }}

# =============================================================================
# ROBOTS.TXT
# =============================================================================
- name: USE_ROBOTSTXT
  value: {{ .robotsTxt.useRobotsTxt | quote }}
{{- if eq .robotsTxt.useRobotsTxt "yes" }}
{{- if .robotsTxt.robotsTxtDarkvisitorsToken }}
- name: ROBOTSTXT_DARKVISITORS_TOKEN
  value: {{ .robotsTxt.robotsTxtDarkvisitorsToken | quote }}
{{- end }}
{{- if .robotsTxt.robotsTxtCommunityLists }}
- name: ROBOTSTXT_COMMUNITY_LISTS
  value: {{ .robotsTxt.robotsTxtCommunityLists | quote }}
{{- end }}
{{- if .robotsTxt.robotsTxtRule }}
- name: ROBOTSTXT_RULE
  value: {{ .robotsTxt.robotsTxtRule | quote }}
{{- end }}
{{- if .robotsTxt.robotsTxtSitemap }}
- name: ROBOTSTXT_SITEMAP
  value: {{ .robotsTxt.robotsTxtSitemap | quote }}
{{- end }}
{{- end }}

# =============================================================================
# SECURITY.TXT
# =============================================================================
- name: USE_SECURITYTXT
  value: {{ .securityTxt.useSecurityTxt | quote }}
{{- if eq .securityTxt.useSecurityTxt "yes" }}
{{- if .securityTxt.securityTxtContact }}
- name: SECURITYTXT_CONTACT
  value: {{ .securityTxt.securityTxtContact | quote }}
{{- end }}
{{- if .securityTxt.securityTxtExpires }}
- name: SECURITYTXT_EXPIRES
  value: {{ .securityTxt.securityTxtExpires | quote }}
{{- end }}
{{- if .securityTxt.securityTxtPolicy }}
- name: SECURITYTXT_POLICY
  value: {{ .securityTxt.securityTxtPolicy | quote }}
{{- end }}
{{- end }}

# =============================================================================
# CROWDSEC INTEGRATION
# =============================================================================
- name: USE_CROWDSEC
  value: {{ .crowdSec.useCrowdSec | quote }}
{{- if eq .crowdSec.useCrowdSec "yes" }}
- name: CROWDSEC_API
  value: {{ .crowdSec.crowdSecApi | quote }}
{{- if .crowdSec.crowdSecApiKey }}
- name: CROWDSEC_API_KEY
  value: {{ .crowdSec.crowdSecApiKey | quote }}
{{- end }}
- name: CROWDSEC_MODE
  value: {{ .crowdSec.crowdSecMode | quote }}
{{- if .crowdSec.crowdSecAppsecUrl }}
- name: CROWDSEC_APPSEC_URL
  value: {{ .crowdSec.crowdSecAppsecUrl | quote }}
{{- end }}
{{- end }}

# =============================================================================
# PHP INTEGRATION
# =============================================================================
{{- if .php.remotePhp }}
- name: REMOTE_PHP
  value: {{ .php.remotePhp | quote }}
- name: REMOTE_PHP_PORT
  value: {{ .php.remotePhpPort | quote }}
{{- if .php.remotePhpPath }}
- name: REMOTE_PHP_PATH
  value: {{ .php.remotePhpPath | quote }}
{{- end }}
{{- end }}
{{- if .php.localPhp }}
- name: LOCAL_PHP
  value: {{ .php.localPhp | quote }}
{{- if .php.localPhpPath }}
- name: LOCAL_PHP_PATH
  value: {{ .php.localPhpPath | quote }}
{{- end }}
{{- end }}

# =============================================================================
# GREYLIST (CONDITIONAL ACCESS)
# =============================================================================
- name: USE_GREYLIST
  value: {{ .greylist.useGreylist | quote }}
{{- if eq .greylist.useGreylist "yes" }}
{{- if .greylist.greylistIp }}
- name: GREYLIST_IP
  value: {{ .greylist.greylistIp | quote }}
{{- end }}
{{- if .greylist.greylistIpUrls }}
- name: GREYLIST_IP_URLS
  value: {{ .greylist.greylistIpUrls | quote }}
{{- end }}
{{- end }}

# =============================================================================
# REVERSE SCAN
# =============================================================================
- name: USE_REVERSE_SCAN
  value: {{ .reverseScan.useReverseScan | quote }}
{{- if eq .reverseScan.useReverseScan "yes" }}
- name: REVERSE_SCAN_PORTS
  value: {{ .reverseScan.reverseScanPorts | quote }}
- name: REVERSE_SCAN_TIMEOUT
  value: {{ .reverseScan.reverseScanTimeout | quote }}
{{- end }}

# =============================================================================
# BACKUP CONFIGURATION
# =============================================================================
- name: USE_BACKUP
  value: {{ .backup.useBackup | quote }}
{{- if eq .backup.useBackup "yes" }}
- name: BACKUP_SCHEDULE
  value: {{ .backup.backupSchedule | quote }}
- name: BACKUP_ROTATION
  value: {{ .backup.backupRotation | quote }}
- name: BACKUP_DIRECTORY
  value: {{ .backup.backupDirectory | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}