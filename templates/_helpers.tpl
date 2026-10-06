{{- define "django-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "django-app.fullname" -}}
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

{{- define "django-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "django-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "django-app.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{ include "django-app.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "django-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "django-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "django-app.secretName" -}}
{{- default (printf "%s-secret" (include "django-app.fullname" .)) .Values.secret.existingSecret }}
{{- end }}

{{- define "django-app.dbClusterName" -}}
{{- printf "%s-db" (include "django-app.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "django-app.dbSecretName" -}}
{{- if .Values.database.credentialsSecret.name }}
{{- .Values.database.credentialsSecret.name }}
{{- else if eq .Values.database.mode "cnpg" }}
{{- printf "%s-app" (include "django-app.dbClusterName" .) }}
{{- else }}
{{- fail "database.credentialsSecret.name is required when database.mode=external" }}
{{- end }}
{{- end }}

{{- define "django-app.image" -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- end }}

{{/* Env shared by the app container and the migrate init container */}}
{{- define "django-app.env" -}}
{{- $s := include "django-app.dbSecretName" . }}
{{- $c := .Values.database.credentialsSecret }}
- name: DJANGO_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "django-app.secretName" . }}
      key: {{ .Values.secret.key }}
- name: DB_HOST
  valueFrom:
    secretKeyRef: {name: {{ $s }}, key: {{ $c.hostKey }}}
- name: DB_PORT
  valueFrom:
    secretKeyRef: {name: {{ $s }}, key: {{ $c.portKey }}}
- name: DB_NAME
  valueFrom:
    secretKeyRef: {name: {{ $s }}, key: {{ $c.nameKey }}}
- name: DB_USER
  valueFrom:
    secretKeyRef: {name: {{ $s }}, key: {{ $c.userKey }}}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef: {name: {{ $s }}, key: {{ $c.passwordKey }}}
{{- end }}
