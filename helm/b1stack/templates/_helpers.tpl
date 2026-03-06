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
  {{- printf "mysql://%s:%s@%s-mysql:3306/%s"
        $ctx.Values.mysql.auth.username
        $ctx.Values.mysql.auth.password
        $ctx.Release.Name
        $module -}}
{{- else -}}
  {{- required (printf "api.secrets.%s_CONNECTION_STRING is required when mysql.enabled=false" (upper $module)) $override -}}
{{- end -}}
{{- end }}
