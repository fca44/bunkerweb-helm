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