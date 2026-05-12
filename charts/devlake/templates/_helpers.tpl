{{/*
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "devlake.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end -}}

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
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "devlake.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}

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
app.kubernetes.io/part-of: devlake
{{- end -}}

{{/*
Common annotations
*/}}
{{- define "devlake.annotations" -}}
meta.helm.sh/release-name: {{ .Release.Name }}
meta.helm.sh/release-namespace: {{ .Release.Namespace }}
{{- end -}}

{{/*
Selector labels (returns YAML string)
*/}}
{{- define "devlake.selectorLabels" -}}
app.kubernetes.io/name: {{ include "devlake.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Selector labels as dict (for matchLabels)
*/}}
{{- define "devlake.selectorLabelsDict" -}}
{{- $labels := dict }}
{{- $_ := set $labels "app.kubernetes.io/name" (include "devlake.name" .) }}
{{- $_ := set $labels "app.kubernetes.io/instance" .Release.Name }}
{{- toYaml $labels }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "devlake.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else if .Values.serviceAccount.create -}}
{{- include "devlake.fullname" . }}-sa
{{- else -}}
default
{{- end -}}
{{- end -}}


{{/*
The ui endpoint prefix
*/}}
{{- define "devlake.grafanaEndpointPrefix" -}}
{{- print .Values.ingress.prefix  "/grafana" | replace "//" "/" | trimAll "/" -}}
{{- end -}}

{{/*
The ui endpoint prefix
*/}}
{{- define "devlake.uiEndpointPrefix" -}}
{{- print .Values.ingress.prefix  "/" | replace "//" "/" | trimAll "/" -}}
{{- end -}}

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
{{- end -}}

{{/*
Database secret name (renamed from devlake.mysql.secret in v2.0.0)
*/}}
{{- define "devlake.db.secret" -}}
{{- if .Values.externalSecrets.enabled -}}
{{- .Values.externalSecrets.secretName -}}
{{- else -}}
{{- if .Values.option.connectionSecretName -}}
{{- .Values.option.connectionSecretName -}}
{{- else -}}
{{ include "devlake.fullname" . }}-db-auth
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Database configmap name (renamed from devlake.mysql.configmap in v2.0.0)
*/}}
{{- define "devlake.db.configmap" -}}
{{- if .Values.option.connectionConfigmapName -}}
{{- .Values.option.connectionConfigmapName -}}
{{- else -}}
{{ include "devlake.fullname" . }}-db-config
{{- end -}}
{{- end -}}

{{- define "devlake.ui.auth.secret" -}}
{{- if .Values.externalSecrets.enabled -}}
{{- .Values.externalSecrets.secretName -}}
{{- else -}}
{{- if .Values.ui.basicAuth.secretName -}}
{{- .Values.ui.basicAuth.secretName -}}
{{- else -}}
{{ include "devlake.fullname" . }}-ui-auth
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "devlake.lake.encryption.secret" -}}
{{- if .Values.externalSecrets.enabled -}}
{{- .Values.externalSecrets.secretName -}}
{{- else -}}
{{- if .Values.lake.encryptionSecret.secretName -}}
{{- .Values.lake.encryptionSecret.secretName -}}
{{- else -}}
{{ include "devlake.fullname" . }}-encryption-secret
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
The database server (v2.0.0: refactored for database.type selector)
*/}}
{{- define "database.server" -}}
{{- if .Values.database.useExternal }}
{{- .Values.database.externalServer }}
{{- else }}
{{- printf "%s-%s" (include "devlake.fullname" .) .Values.database.type }}
{{- end }}
{{- end -}}

{{/*
The database port (v2.0.0: refactored for database.type selector)
*/}}
{{- define "database.port" -}}
{{- if .Values.database.useExternal -}}
{{- .Values.database.externalPort -}}
{{- else -}}
{{- if eq .Values.database.type "mysql" -}}
{{- "3306" -}}
{{- else if eq .Values.database.type "postgresql" -}}
{{- "5432" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
The database image (v2.0.0: new helper for database.type selector with digest support)
*/}}
{{- define "database.image" -}}
{{- $image := "" -}}
{{- if and .Values.database.image.repository (ne .Values.database.image.repository "") -}}
  {{- $image = printf "%s:%s" .Values.database.image.repository (.Values.database.image.tag | toString) -}}
{{- else -}}
  {{- if eq .Values.database.type "mysql" -}}
    {{- $image = "mysql:8" -}}
  {{- else if eq .Values.database.type "postgresql" -}}
    {{- $image = "postgres:14" -}}
  {{- end -}}
{{- end -}}
{{- if eq .Values.database.type "mysql" -}}
  {{- if .Values.imageDigests.database.mysql -}}
    {{- printf "%s@%s" $image .Values.imageDigests.database.mysql -}}
  {{- else -}}
    {{- $image -}}
  {{- end -}}
{{- else if eq .Values.database.type "postgresql" -}}
  {{- if .Values.imageDigests.database.postgresql -}}
    {{- printf "%s@%s" $image .Values.imageDigests.database.postgresql -}}
  {{- else -}}
    {{- $image -}}
  {{- end -}}
{{- end -}}
{{- end -}}


{{/*
Database uid based on type (mysql=999, postgresql=70)
*/}}
{{- define "database.uid" -}}
{{- if eq .Values.database.type "mysql" -}}
{{- "999" -}}
{{- else if eq .Values.database.type "postgresql" -}}
{{- "70" -}}
{{- end -}}
{{- end -}}

{{/*
Lake image with optional digest
*/}}
{{- define "devlake.lake.image" -}}
{{- $image := printf "%s:%s" .Values.lake.image.repository (.Values.lake.image.tag | default .Values.imageTag) -}}
{{- if .Values.imageDigests.lake -}}
{{- printf "%s@%s" $image .Values.imageDigests.lake -}}
{{- else -}}
{{- $image -}}
{{- end -}}
{{- end -}}

{{/*
UI image with optional digest
*/}}
{{- define "devlake.ui.image" -}}
{{- $image := printf "%s:%s" .Values.ui.image.repository (.Values.ui.image.tag | default .Values.imageTag) -}}
{{- if .Values.imageDigests.ui -}}
{{- printf "%s@%s" $image .Values.imageDigests.ui -}}
{{- else -}}
{{- $image -}}
{{- end -}}
{{- end -}}

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
{{- end -}}

{{/*
Pod Anti-Affinity helper
*/}}
{{- define "devlake.podAntiAffinity" -}}
{{- if .enabled }}
affinity:
  podAntiAffinity:
    {{- if eq .type "required" }}
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchLabels:
          app.kubernetes.io/name: {{ include "devlake.name" .root }}
          app.kubernetes.io/instance: {{ .root.Release.Name }}
          devlakeComponent: {{ .componentName }}
      topologyKey: kubernetes.io/hostname
    {{- else }}
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: {{ include "devlake.name" .root }}
            app.kubernetes.io/instance: {{ .root.Release.Name }}
            devlakeComponent: {{ .componentName }}
        topologyKey: kubernetes.io/hostname
    {{- end }}
{{- end }}
{{- end -}}

{{/*
PodDisruptionBudget helper - uses maxUnavailable when replicaCount=1, minAvailable otherwise
*/}}
{{- define "devlake.podDisruptionBudget" -}}
{{- if .pdb.enabled }}
{{- if eq (int .replicaCount) 1 }}
maxUnavailable: 1
{{- else }}
minAvailable: {{ .pdb.minAvailable }}
{{- end }}
{{- end }}
{{- end -}}
