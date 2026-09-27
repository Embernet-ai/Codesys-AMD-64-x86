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

{{/*
Host ports that move when hostNetwork is on, as JSON: {"runtime":11750,...,
"udpPortIndex":"2"}. Empty when hostNetwork is off or nothing is set, and then
every template renders exactly what it always has.

Why only under hostNetwork: that is the only mode where two runtimes on one
node fight over a port, because the pod IS the node's network. It is also the
mode where Kubernetes insists hostPort equals containerPort, so a host port
cannot be moved on its own; the runtime has to listen on the new port too.
That is what the runtimeConfig script does with these (see deployment.yaml).
*/}}
{{- define "codesys-control-for-linux-sl.hostPorts" -}}
{{- $out := dict -}}
{{- if .Values.network.hostNetwork -}}
{{- $hp := .Values.network.hostPorts | default dict -}}
{{- range $k := list "runtime" "gateway" "opcua" -}}
{{- with index $hp $k -}}
{{- $p := int . -}}
{{- if or (lt $p 1) (gt $p 65535) -}}
{{- fail (printf "network.hostPorts.%s must be a port number, got %v" $k .) -}}
{{- end -}}
{{- $_ := set $out $k $p -}}
{{- end -}}
{{- end -}}
{{- $idx := .Values.network.udpPortIndex -}}
{{- if and (not (kindIs "invalid" $idx)) (ne (toString $idx) "") -}}
{{- if not (has (toString $idx) (list "0" "1" "2" "3")) -}}
{{- fail (printf "network.udpPortIndex must be 0, 1, 2, or 3 (UDP 1740 to 1743), got %v" $idx) -}}
{{- end -}}
{{- $_ := set $out "udpPortIndex" (toString $idx) -}}
{{- end -}}
{{- end -}}
{{- toJson $out -}}
{{- end }}

{{/*
setkey FILE SECTION KEY VALUE for the runtime config scripts: KEY=VALUE inside
the FIRST [SECTION] (the runtime reads only the first copy of a section),
replacing any KEY= line already there, and adding the section when the file has
none. Written with awk because the images ship mawk, sed, and grep and nothing
fancier. The file is rewritten in place with cat so its owner and mode stay.
*/}}
{{- define "codesys.setkey" -}}
setkey() {
  awk -v s="[$2]" -v k="$3" -v v="$4" '
    { line = $0; sub(/\r$/, "", line) }
    line ~ /^\[/ {
      if (insec && !done) { print k "=" v; done = 1 }
      insec = (!done && line == s)
      print; next
    }
    insec && index(line, k "=") == 1 { next }
    { print }
    END {
      if (!done && insec) print k "=" v
      else if (!done) { print ""; print s; print k "=" v }
    }' "$1" > "$1.setkey" && cat "$1.setkey" > "$1" && rm -f "$1.setkey"
}
{{- end }}
