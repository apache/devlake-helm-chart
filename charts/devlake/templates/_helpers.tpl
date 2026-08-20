{{/*
Expand the name of the chart.
*/}}
{{- define "devlake.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "devlake.fullname" -}}
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
{{- define "devlake.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "devlake.labels" -}}
helm.sh/chart: {{ include "devlake.chart" . }}
{{ include "devlake.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "devlake.selectorLabels" -}}
app.kubernetes.io/name: {{ include "devlake.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "devlake.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "devlake.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
The ui endpoint prefix
*/}}
{{- define "devlake.grafanaEndpointPrefix" -}}
{{- print .Values.ingress.prefix  "/grafana" | replace "//" "/" | trimAll "/" -}}
{{- end }}

{{/*
The ui endpoint prefix
*/}}
{{- define "devlake.uiEndpointPrefix" -}}
{{- print .Values.ingress.prefix  "/" | replace "//" "/" | trimAll "/" -}}
{{- end }}

{{/*
The ui endpoint
*/}}
{{- define "devlake.uiEndpoint" -}}
{{- if .Values.ingress.enabled }}
{{- $uiPortString := "" }}
{{- if .Values.ingress.enableHttps }}
{{- if ne 443 ( .Values.ingress.httpsPort | int) }}
{{- $uiPortString = printf ":%d" ( .Values.ingress.httpsPort | int) }}
{{- end }}
{{- printf "https://%s%s/%s" .Values.ingress.hostname $uiPortString (include "devlake.uiEndpointPrefix" .) }}
{{- else }}
{{- if ne 80 ( .Values.ingress.httpPort | int) }}
{{- $uiPortString = printf ":%d" ( .Values.ingress.httpPort | int) }}
{{- end }}
{{- printf "http://%s%s/%s" .Values.ingress.hostname $uiPortString (include "devlake.uiEndpointPrefix" .) }}
{{- end }}
{{- end }}
{{- end }}

{{- define "devlake.mysql.secret" -}}
{{- if .Values.option.connectionSecretName -}}
{{- .Values.option.connectionSecretName -}}
{{- else -}}
{{ include "devlake.fullname" . }}-db-connection
{{- end -}}
{{- end -}}

{{- define "devlake.mysql.configmap" -}}
{{- if .Values.option.connectionConfigmapName -}}
{{- .Values.option.connectionConfigmapName -}}
{{- else -}}
{{ include "devlake.fullname" . }}-config
{{- end -}}
{{- end -}}

{{- define "devlake.ui.auth.secret" -}}
{{- if .Values.ui.basicAuth.secretName -}}
{{- .Values.ui.basicAuth.secretName -}}
{{- else -}}
{{ include "devlake.fullname" . }}-ui-auth
{{- end -}}
{{- end -}}

{{- define "devlake.lake.encryption.secret" -}}
{{- if .Values.lake.encryptionSecret.secretName -}}
{{- .Values.lake.encryptionSecret.secretName -}}
{{- else -}}
{{ include "devlake.fullname" . }}-encryption-secret
{{- end -}}
{{- end -}}

{{/*
The mysql server
*/}}
{{- define "mysql.server" -}}
{{- if .Values.mysql.useExternal }}
{{- .Values.mysql.externalServer }}
{{- else }}
{{- print (include "devlake.fullname" . ) "-mysql" }}
{{- end }}
{{- end }}


{{/*
The mysql port
*/}}
{{- define "mysql.port" -}}
{{- if .Values.mysql.useExternal }}
{{- .Values.mysql.externalPort }}
{{- else }}
{{- .Values.mysql.service.port }}
{{- end }}
{{- end }}



{{/*
The database server
*/}}
{{- define "database.server" -}}
{{- if eq .Values.option.database "mysql" }}
{{- include "mysql.server" . }}
{{- end }}
{{- end }}


{{/*
The database port
*/}}
{{- define "database.port" -}}
{{- if eq .Values.option.database "mysql" }}
{{- include "mysql.port" . }}
{{- end }}
{{- end }}


{{/*
The probe for check database connection
*/}}
{{- define "common.initContainerWaitDatabase" -}}
- name: waiting-database-ready
  image: "{{ .Values.alpine.image.repository }}:{{ .Values.alpine.image.tag }}"
  imagePullPolicy: {{ .Values.alpine.image.pullPolicy }}
  command:
    - 'sh'
    - '-c'
    - |
      until nc -z -w 2 {{ include "database.server" . }} {{ include "database.port" . }} ; do
        echo wait for database ready ...
        sleep 2
      done
      echo database is ready
{{- end }}
