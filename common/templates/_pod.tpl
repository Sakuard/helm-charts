{{- define "common.pod" -}}
serviceAccountName: {{ include "common.serviceAccountName" . }}
terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds }}

{{- with .Values.imagePullSecrets }}
imagePullSecrets: {{ include "bettertpl" (dict "value" . "context" $) | nindent 2 }}
{{- end -}}

{{- with .Values.podSecurityContext }}
securityContext: {{ include "bettertpl" (dict "value" . "context" $) | nindent 2 }}
{{- end -}}

{{- with .Values.initContainers }}
initContainers: {{ include "bettertpl" (dict "value" . "context" $) | nindent 2 }}
{{- end }}

containers:
  - name: {{ include "common.fullname" . }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}

    {{- with .Values.securityContext }}
    securityContext: {{ include "bettertpl" (dict "value" . "context" $) | nindent 6 }}
    {{- end -}}

    {{- with .Values.args }}
    args: {{ include "bettertpl" (dict "value" . "context" $) | nindent 6 }}
    {{- end -}}

    {{- with .Values.service.ports }}
    ports:
      {{- range $key, $port := . }}
      {{- if or $port.enabled (eq $port.enabled nil) }}
      - name: {{ $key }}
        containerPort: {{ $port.containerPort }}
        protocol: {{ $port.protocol }}
        {{- with $port.hostPort }}
        hostPort: {{ . }}
        {{- end }}
      {{- end }}
      {{- end }}
    {{- end -}}

    {{- with .Values.resources }}
    resources: {{ include "bettertpl" (dict "value" . "context" $) | nindent 6 }}
    {{- end -}}

    {{- with .Values.lifecycle }}
    lifecycle: {{ include "bettertpl" (dict "value" . "context" $) | nindent 6 }}
    {{- end -}}

    {{- with .Values.startupProbe }}
    {{- if or .enabled (eq .enabled nil) }}
    startupProbe: {{ include "bettertpl" (dict "value" (omit . "enabled") "context" $) | nindent 6 }}
    {{- end }}
    {{- end -}}

    {{- with .Values.livenessProbe }}
    {{- if or .enabled (eq .enabled nil) }}
    livenessProbe: {{ include "bettertpl" (dict "value" (omit . "enabled") "context" $) | nindent 6 }}
    {{- end }}
    {{- end -}}

    {{- with .Values.readinessProbe }}
    {{- if or .enabled (eq .enabled nil) }}
    readinessProbe: {{ include "bettertpl" (dict "value" (omit . "enabled") "context" $) | nindent 6 }}
    {{- end }}
    {{- end -}}

    {{- if or .Values.env .Values.createExternalSecret }}
    env:
      {{- range $key, $value := .Values.env }}
      - name: {{ $key }}
        value: {{ $value | quote }}
      {{- end -}}
      {{- with .Values.createExternalSecret }}
      {{- $secretName := .secretName }}
      {{- range $key := .keys }}
      - name: {{ $key }}
        valueFrom:
          secretKeyRef:
            name: {{ $secretName }}
            key: {{ $key }}
      {{- end -}}
      {{- end -}}
    {{- end -}}

    {{- with .Values.envFrom }}
    envFrom:
      {{- range $k, $v := . }}
      {{- if $v.configMapRef }}
      - configMapRef:
          name: {{ include "bettertpl" (dict "value" $v.configMapRef "context" $) }}
          optional: {{ $v.optional | default false }}
      {{- else if $v.secretRef }}
      - secretRef:
          name: {{ include "bettertpl" (dict "value" $v.secretRef "context" $) }}
          optional: {{ $v.optional | default false }}
      {{- end }}
      {{- end }}
    {{- end -}}

    {{- /* extraVolumeMounts 與 persistence 合併成單一 volumeMounts key（避免重複 key） */ -}}
    {{- $p := .Values.persistence }}
    {{- $persOn := and $p $p.enabled }}
    {{- if or .Values.extraVolumeMounts $persOn }}
    volumeMounts:
      {{- with .Values.extraVolumeMounts }}
      {{- include "bettertpl" (dict "value" . "context" $) | nindent 6 }}
      {{- end }}
      {{- if $persOn }}
      {{- if eq $p.type "gcs-fuse" }}
      - name: gcs-fuse-csi-static
        mountPath: {{ $p.mountPath }}
      {{- else if eq $p.type "disk" }}
      - name: persistence-{{ include "common.fullname" $ }}
        mountPath: {{ $p.mountPath }}
      {{- end }}
      {{- end }}
    {{- end -}}

  {{- with .Values.extraContainers }}
  {{- include "bettertpl" (dict "value" . "context" $) | nindent 2 }}
  {{- end -}}

{{- /* extraVolumes 與 persistence 合併成單一 volumes key（避免重複 key） */ -}}
{{- $p := .Values.persistence }}
{{- $persOn := and $p $p.enabled }}
{{- if or .Values.extraVolumes $persOn }}
volumes:
  {{- with .Values.extraVolumes }}
  {{- include "bettertpl" (dict "value" . "context" $) | nindent 2 }}
  {{- end }}
  {{- if $persOn }}
  - name: {{ if eq $p.type "gcs-fuse" }}gcs-fuse-csi-static{{ else }}persistence-{{ include "common.fullname" $ }}{{ end }}
    persistentVolumeClaim:
      claimName: {{ include "common.fullname" $ }}-pvc
  {{- end }}
{{- end -}}

{{- with .Values.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end -}}

{{- with .Values.nodeSelector }}
nodeSelector: {{ include "bettertpl" (dict "value" . "context" $) | nindent 2 }}
{{- end -}}

{{- with .Values.affinity }}
affinity: {{ include "bettertpl" (dict "value" . "context" $) | nindent 2 }}
{{- end -}}

{{- with .Values.tolerations }}
tolerations: {{ include "bettertpl" (dict "value" . "context" $) | nindent 2 }}
{{- end -}}

{{- with .Values.topologySpreadConstraints }}
topologySpreadConstraints: {{ include "bettertpl" (dict "value" . "context" $) | nindent 2 }}
{{- end -}}

{{- with .Values.hostAliases }}
hostAliases: {{ . | toYaml | nindent 2 }}
{{- end -}}

{{- end }}