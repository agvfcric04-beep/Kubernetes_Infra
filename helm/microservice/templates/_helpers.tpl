{{- define "microservice.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride -}}
{{- else if .Release.Name -}}
{{- .Release.Name -}}
{{- else -}}
{{- .Chart.Name -}}
{{- end -}}
{{- end -}}

{{- define "microservice.name" -}}
{{ include "microservice.fullname" . }}-frontend
{{- end -}}

{{- define "microservice.labels" -}}
app.kubernetes.io/name: {{ include "microservice.name" . }}
app.kubernetes.io/instance: {{ include "microservice.fullname" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: frontend
{{- end -}}

{{- define "microservice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "microservice.name" . }}
app.kubernetes.io/instance: {{ include "microservice.fullname" . }}
{{- end -}}

{{- define "microservice.postgresName" -}}
{{ include "microservice.fullname" . }}-postgres
{{- end -}}
