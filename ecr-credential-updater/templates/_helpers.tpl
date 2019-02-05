{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "ecr-credential-updater.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ecr-credential-updater.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ecr-credential-updater.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ecr-credential-updater.job" }}
spec:
  template:
    metadata:
      creationTimestamp: null
    spec:
      containers:
      - command:
        - /bin/sh
        - -c
        - |-
          REGION={{ .Values.aws.region | quote }}
          SECRET_NAME=${REGION}-ecr-registry
          EMAIL=anymail.doesnt.matter@email.com
          TOKEN=`aws ecr get-login --region ${REGION} --no-include-email | cut -d' ' -f6`
          echo "ENV variables setup done."
          kubectl delete secret --ignore-not-found $SECRET_NAME
          kubectl create secret docker-registry $SECRET_NAME \
          --docker-server={{ .Values.ecrUrl }} \
          --docker-username=AWS \
          --docker-password="${TOKEN}" \
          --docker-email="${EMAIL}"
          echo "Secret created by name. $SECRET_NAME"
          kubectl patch serviceaccount default -p '{"imagePullSecrets":[{"name":"'$SECRET_NAME'"}]}'
          echo "All done."
        env:
        - name: AWS_DEFAULT_REGION
          value: {{ .Values.aws.region | quote }}
        - name: AWS_SECRET_ACCESS_KEY
          value: {{ .Values.aws.secretKey | quote }}
        - name: AWS_ACCESS_KEY_ID
          value: {{ .Values.aws.accessKeyId | quote }}
        image: odaniait/aws-kubectl:latest
        imagePullPolicy: IfNotPresent
        name: {{ template "ecr-credential-updater.fullname" . }}
        resources: {}
        securityContext:
          capabilities: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: Default
      hostNetwork: true
      restartPolicy: Never
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      serviceAccount: {{ .Values.serviceAccount }}
{{- end }}
