{{/* Service name: required, fails the render with a clear message if missing */}}
{{- define "microservice.name" -}}
{{- required "values: 'name' is required" .Values.name -}}
{{- end -}}

{{/* Service account name: defaults to the service name */}}
{{- define "microservice.serviceAccountName" -}}
{{- default (include "microservice.name" .) .Values.serviceAccount.name -}}
{{- end -}}

{{/* Standard Kubernetes labels on every object */}}
{{- define "microservice.labels" -}}
app.kubernetes.io/name: {{ include "microservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: nimbus
{{- end -}}

{{/* Labels used to match pods to the Deployment and Service (must never change) */}}
{{- define "microservice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "microservice.name" . }}
{{- end -}}