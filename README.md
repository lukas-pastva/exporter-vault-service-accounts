# exporter-vault-service-accounts
Prometheus Exporter that scrapes Kubernetes Service account annotations specific for Hashicorp Vault

```yaml
# Cluster role
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sa-annotation-monitor-role
rules:
  - apiGroups: [""]
    resources: ["serviceaccounts"]
    verbs: ["get", "list", "watch"]

# Prometheus rule
groups:
- name: ServiceAccountAnnotationAlerts
  rules:
  - alert: VaultAliasMetadataEnvMissing
    expr: sa_vault_alias_metadata_env{annotation_value=""} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Missing vault.hashicorp.com/alias-metadata-env Annotation"
      description: "Service Account '{{ $labels.service_account }}' in namespace '{{ $labels.namespace }}' is missing the 'vault.hashicorp.com/alias-metadata-env' annotation."

  - alert: VaultAliasMetadataEnvInvalidSlash
    expr: sa_vault_alias_metadata_env{annotation_value!=""} == 1 and (
           # Check if the annotation value does not contain at least one '/'
           (sa_vault_alias_metadata_env{annotation_value!=""}.annotation_value !~ "/") or
           # Check if the annotation value starts with '/'
           (sa_vault_alias_metadata_env{annotation_value!=""}.annotation_value =~ "^/")
         )
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Invalid vault.hashicorp.com/alias-metadata-env Annotation"
      description: "Service Account '{{ $labels.service_account }}' in namespace '{{ $labels.namespace }}' has an invalid 'vault.hashicorp.com/alias-metadata-env' annotation value. It must contain at least one '/' and cannot start with '/'. Current value: '{{ $labels.annotation_value }}'."
```
