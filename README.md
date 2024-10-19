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
```
