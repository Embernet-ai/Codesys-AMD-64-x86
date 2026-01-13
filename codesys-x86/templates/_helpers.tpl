{{/*
Expand the name of the chart.
*/}}
{{- define "codesys-x86.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "codesys-x86.fullname" -}}
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
{{- define "codesys-x86.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "codesys-x86.labels" -}}
helm.sh/chart: {{ include "codesys-x86.chart" . }}
{{ include "codesys-x86.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
architecture: {{ .Values.architecture }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "codesys-x86.selectorLabels" -}}
app.kubernetes.io/name: {{ include "codesys-x86.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: codesys-runtime
architecture: {{ .Values.architecture }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "codesys-x86.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "codesys-x86.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the namespace
*/}}
{{- define "codesys-x86.namespace" -}}
{{- if .Values.namespace.create }}
{{- .Values.namespace.name }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Get resource limits based on architecture
*/}}
{{- define "codesys-x86.resources" -}}
{{- if eq .Values.architecture "amd64" }}
{{- toYaml .Values.resources.amd64 }}
{{- else if eq .Values.architecture "386" }}
{{- toYaml .Values.resources.i386 }}
{{- else }}
{{- toYaml .Values.resources.amd64 }}
{{- end }}
{{- end }}

{{/*
Get image repository
*/}}
{{- define "codesys-x86.image" -}}
{{- if .Values.image.tag }}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository .Values.image.tag }}
{{- else }}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository .Chart.AppVersion }}
{{- end }}
{{- end }}
