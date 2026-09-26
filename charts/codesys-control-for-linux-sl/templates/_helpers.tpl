{{/*
Expand the name of the chart.
*/}}
{{- define "codesys-control-for-linux-sl.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "codesys-control-for-linux-sl.fullname" -}}
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
{{- define "codesys-control-for-linux-sl.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "codesys-control-for-linux-sl.labels" -}}
helm.sh/chart: {{ include "codesys-control-for-linux-sl.chart" . }}
{{ include "codesys-control-for-linux-sl.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "codesys-control-for-linux-sl.selectorLabels" -}}
app.kubernetes.io/name: {{ include "codesys-control-for-linux-sl.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
EmberNET Store Labels — The Big Four
These labels enable Industrial Dashboard discovery for pod and service resources.
*/}}
{{- define "codesys-control-for-linux-sl.storeLabels" -}}
embernet.ai/store-app: "true"
embernet.ai/gui-type: {{ .Values.gui.type | default "web" | quote }}
embernet.ai/app-name: {{ include "codesys-control-for-linux-sl.name" . | quote }}
{{- if and .Values.sidecarProxy .Values.sidecarProxy.enabled }}
embernet.ai/gui-port: {{ .Values.sidecarProxy.listenPort | quote }}
{{- else }}
embernet.ai/gui-port: {{ .Values.gui.port | default .Values.service.port | quote }}
{{- end }}
{{- end }}
