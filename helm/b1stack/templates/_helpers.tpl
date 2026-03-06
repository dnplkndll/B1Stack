{{/*
Expand the name of the chart.
*/}}
{{- define "b1stack.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "b1stack.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Resolve hostname for a service.
Usage: include "b1stack.hostname" (list . "api" "api")
  Args: [context, svcKey, prefix]
  - Explicit hostname (svc.ingress.hostname) wins if non-empty.
  - Otherwise: {prefix}-{baseDomain} (dash separator for wildcard cert compat).
  - When prefix is empty (b1app): just {baseDomain}.
*/}}
{{- define "b1stack.hostname" -}}
{{- $ctx    := index . 0 -}}
{{- $svcKey := index . 1 -}}
{{- $prefix := index . 2 -}}
{{- $svc    := index $ctx.Values $svcKey -}}
{{- if $svc.ingress.hostname -}}
  {{- $svc.ingress.hostname -}}
{{- else if $ctx.Values.global.baseDomain -}}
  {{- if $prefix -}}
    {{- printf "%s-%s" $prefix $ctx.Values.global.baseDomain -}}
  {{- else -}}
    {{- $ctx.Values.global.baseDomain -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{/*
Check if ingress should be enabled for a service.
True when service enabled AND (explicit ingress.enabled OR baseDomain is set).
Usage: include "b1stack.ingressEnabled" (list . "api")
*/}}
{{- define "b1stack.ingressEnabled" -}}
{{- $ctx    := index . 0 -}}
{{- $svcKey := index . 1 -}}
{{- $svc    := index $ctx.Values $svcKey -}}
{{- if and $svc.enabled (or $svc.ingress.enabled $ctx.Values.global.baseDomain) -}}
true
{{- end -}}
{{- end }}

{{/*
Resolve ingress class name. Per-service overrides global.
Usage: include "b1stack.ingressClassName" (list . "api")
*/}}
{{- define "b1stack.ingressClassName" -}}
{{- $ctx    := index . 0 -}}
{{- $svcKey := index . 1 -}}
{{- $svc    := index $ctx.Values $svcKey -}}
{{- $svc.ingress.className | default $ctx.Values.global.ingress.className | default "nginx" -}}
{{- end }}

{{/*
Check if TLS should be enabled. Per-service overrides global.
Also true when clusterIssuer is set (cert-manager implies TLS).
Usage: include "b1stack.ingressTls" (list . "api")
*/}}
{{- define "b1stack.ingressTls" -}}
{{- $ctx    := index . 0 -}}
{{- $svcKey := index . 1 -}}
{{- $svc    := index $ctx.Values $svcKey -}}
{{- if or $svc.ingress.tls $ctx.Values.global.ingress.tls $ctx.Values.global.ingress.clusterIssuer -}}
true
{{- end -}}
{{- end }}

{{/*
Merge ingress annotations. Global + per-service + auto cert-manager clusterIssuer.
Usage: include "b1stack.ingressAnnotations" (list . "api") | nindent 4
*/}}
{{- define "b1stack.ingressAnnotations" -}}
{{- $ctx    := index . 0 -}}
{{- $svcKey := index . 1 -}}
{{- $svc    := index $ctx.Values $svcKey -}}
{{- $merged := dict -}}
{{- $_ := merge $merged $svc.ingress.annotations $ctx.Values.global.ingress.annotations -}}
{{- if and $ctx.Values.global.ingress.clusterIssuer (not (hasKey $merged "cert-manager.io/cluster-issuer")) -}}
  {{- $_ := set $merged "cert-manager.io/cluster-issuer" $ctx.Values.global.ingress.clusterIssuer -}}
{{- end -}}
{{- if gt (len $merged) 0 -}}
{{- toYaml $merged -}}
{{- else -}}
{}
{{- end -}}
{{- end }}

{{/*
Auto-generate or look up a secret value.
Usage: include "b1stack.autoSecret" (list . "secretName" "key" 24)
  - Lookup existing K8s secret for stability across upgrades.
  - If no existing secret (fresh install or helm template), generate randAlphaNum.
  Args: [context, secretName, key, length]
*/}}
{{- define "b1stack.autoSecret" -}}
{{- $ctx        := index . 0 -}}
{{- $secretName := index . 1 -}}
{{- $key        := index . 2 -}}
{{- $length     := index . 3 -}}
{{- $existing   := lookup "v1" "Secret" $ctx.Release.Namespace $secretName -}}
{{- if and $existing (hasKey $existing.data $key) -}}
  {{- index $existing.data $key | b64dec -}}
{{- else -}}
  {{- randAlphaNum $length -}}
{{- end -}}
{{- end }}

{{/*
Resolve a DB connection string.
Usage: include "b1stack.connStr" (list "membership" . .Values.api.secrets.MEMBERSHIP_CONNECTION_STRING)
  - When mysql.enabled=true and no manual override, auto-computes from mysql.auth values.
  - Manual override (even empty string skipped; use "mysql://..." to override).
  - When mysql.enabled=false, the explicit value is required.
*/}}
{{- define "b1stack.connStr" -}}
{{- $module   := index . 0 -}}
{{- $ctx      := index . 1 -}}
{{- $override := index . 2 -}}
{{- if $override -}}
  {{- $override -}}
{{- else if $ctx.Values.mysql.enabled -}}
  {{- $pw := $ctx.Values.mysql.auth.password -}}
  {{- if not $pw -}}
    {{- $mysqlSecret := lookup "v1" "Secret" $ctx.Release.Namespace (printf "%s-mysql" $ctx.Release.Name) -}}
    {{- if and $mysqlSecret (hasKey $mysqlSecret.data "mysql-password") -}}
      {{- $pw = index $mysqlSecret.data "mysql-password" | b64dec -}}
    {{- end -}}
  {{- end -}}
  {{- if not $pw -}}
    {{- fail "mysql.auth.password is empty and the mysql secret was not found. Set mysql.auth.password or ensure the mysql sub-chart has been installed." -}}
  {{- end -}}
  {{- printf "mysql://%s:%s@%s-mysql:3306/%s"
        $ctx.Values.mysql.auth.username
        $pw
        $ctx.Release.Name
        $module -}}
{{- else -}}
  {{- required (printf "api.secrets.%s_CONNECTION_STRING is required when mysql.enabled=false" (upper $module)) $override -}}
{{- end -}}
{{- end }}
