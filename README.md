# Apache DevLake Helm Chart

<!--
Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements.  See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The ASF licenses this file to You under the Apache License, Version 2.0
(the "License"); you may not use this file except in compliance with
the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

[![Release Charts](https://github.com/apache/incubator-devlake-helm-chart/actions/workflows/release.yaml/badge.svg)](https://github.com/apache/incubator-devlake-helm-chart/actions/workflows/release.yaml)
[![Helm Version](https://img.shields.io/badge/Helm-v3.6%2B-blue)](https://helm.sh)
[![Kubernetes Version](https://img.shields.io/badge/Kubernetes-v1.19%2B-blue)](https://kubernetes.io)

Production-ready Helm chart for deploying [Apache DevLake](https://devlake.apache.org/), an open-source dev data platform that ingests, analyzes, and visualizes fragmented data from DevOps tools to distill insights for engineering productivity.

## Table of Contents

- [Apache DevLake Helm Chart](#apache-devlake-helm-chart)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
    - [Core Capabilities](#core-capabilities)
    - [Security](#security)
    - [Operations](#operations)
    - [Enterprise Features](#enterprise-features)
  - [Prerequisites](#prerequisites)
  - [Quick Start](#quick-start)
    - [Installation](#installation)
    - [Upgrade](#upgrade)
    - [Uninstallation](#uninstallation)
  - [Configuration](#configuration)
    - [Database Options](#database-options)
      - [MySQL (Default)](#mysql-default)
      - [PostgreSQL](#postgresql)
    - [Storage Configuration](#storage-configuration)
    - [Security Configuration](#security-configuration)
      - [External Secrets Operator](#external-secrets-operator)
      - [Network Policies](#network-policies)
      - [Image Digest Pinning](#image-digest-pinning)
  - [Deployment Scenarios](#deployment-scenarios)
    - [NodePort (Simple Access)](#nodeport-simple-access)
    - [Ingress (HTTP)](#ingress-http)
    - [Ingress (HTTPS with TLS)](#ingress-https-with-tls)
    - [Production Deployment (Full Security)](#production-deployment-full-security)
  - [Operations](#operations-1)
    - [Backup and Restore](#backup-and-restore)
      - [Enable Automated Backups](#enable-automated-backups)
      - [Manual Backup](#manual-backup)
      - [Restore](#restore)
    - [Monitoring](#monitoring)
      - [Prometheus Metrics](#prometheus-metrics)
      - [Health Checks](#health-checks)
    - [Scaling](#scaling)
      - [Horizontal Pod Autoscaling](#horizontal-pod-autoscaling)
      - [Multi-AZ Deployment](#multi-az-deployment)
  - [Development](#development)
    - [Local Development](#local-development)
    - [Contributing](#contributing)
  - [License](#license)
  - [Acknowledgments](#acknowledgments)

## Features

### Core Capabilities
- **Multi-Database Support**: MySQL 8.x and PostgreSQL 14.x with embedded or external database options
- **Production-Ready Defaults**: Secure by default with ClusterIP service, non-root containers, read-only filesystems
- **Flexible Deployment**: NodePort, LoadBalancer, or Ingress (HTTP/HTTPS) with optional basic authentication

### Security
- **Network Isolation**: NetworkPolicy support for database, backend, and UI layers
- **Secrets Management**: Native Kubernetes Secrets with optional External Secrets Operator integration
- **RBAC**: ServiceAccount with least-privilege configuration
- **Security Hardening**: Read-only root filesystems, dropped capabilities, seccomp profiles

### Operations
- **Automated Backups**: CronJob-based database backups with configurable retention
- **High Availability**: HorizontalPodAutoscaler support for backend and UI components
- **Observability**: Prometheus metrics, structured JSON logging, health probes
- **Migration Support**: Built-in database migration job for schema management

### Enterprise Features
- **External Database**: Connect to managed RDS, Cloud SQL, or Azure Database services
- **External Grafana**: Integration with existing Grafana instances
- **Custom Images**: SHA256 digest pinning for supply chain security
- **Pod Scheduling**: Anti-affinity rules and topology spread constraints

## Prerequisites

- **Kubernetes**: 1.19.0 or higher
- **Helm**: 3.6.0 or higher
- **Storage**: PersistentVolume provisioner support (or hostPath for development)
- **Resources**: Minimum 2 CPU cores and 4GB RAM available in cluster

## Quick Start

### Installation

1. **Add the Helm repository**:

```bash
helm repo add devlake https://apache.github.io/incubator-devlake-helm-chart
helm repo update
```

2. **Generate encryption secret** (required):

```bash
ENCRYPTION_SECRET=$(openssl rand -base64 2000 | tr -dc 'A-Z' | fold -w 128 | head -n 1)
```

3. **Install with MySQL** (default):

```bash
helm install devlake devlake/devlake \
  --set database.password=<strong-password> \
  --set database.mysql.rootPassword=<strong-root-password> \
  --set lake.encryptionSecret.secret=$ENCRYPTION_SECRET
```

4. **Install with PostgreSQL**:

```bash
helm install devlake devlake/devlake \
  --set database.type=postgresql \
  --set database.password=<strong-password> \
  --set lake.encryptionSecret.secret=$ENCRYPTION_SECRET \
  --set grafana.enabled=false
```

5. **Access the application**:

For minikube users:
```bash
kubectl port-forward service/devlake-ui 4000:4000
```

Then visit: http://localhost:4000

### Verifying Signed Releases

All Helm chart releases are signed with [Sigstore cosign](https://docs.sigstore.dev/cosign/overview/) for supply chain security.

**Verify OCI chart signature**:

```bash
# Install cosign
brew install cosign

# Verify chart signature (example for version 0.1.0)
cosign verify ghcr.io/apache/incubator-devlake-helm-chart/devlake:0.1.0 \
  --certificate-identity-regexp="https://github.com/apache/incubator-devlake-helm-chart/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com"
```

**Verify SLSA provenance**:

```bash
# Verify chart provenance attestation
gh attestation verify devlake-0.1.0.tgz --repo apache/incubator-devlake-helm-chart
```

All releases include:
- **SBOM (SPDX)**: Software Bill of Materials listing chart dependencies
- **Cosign signature**: Keyless signature using GitHub OIDC
- **SLSA provenance**: Build provenance attestation

### Upgrade

**From v0.18.x or later**:

```bash
helm repo update
helm upgrade devlake devlake/devlake
```

**From v0.17.x or earlier** (requires ENCRYPTION_SECRET):

1. Extract existing encryption key:
```bash
kubectl exec -it devlake-lake-0 -- cat /app/config/.env | grep ENCODE_KEY
```

2. Upgrade with the extracted key:
```bash
helm repo update
helm upgrade devlake devlake/devlake \
  --set lake.encryptionSecret.secret=<EXTRACTED_KEY>
```

**Note**: Upgrading from v0.17.x may require deleting the Grafana deployment first if you encounter selector immutability errors. See [HelmSetup.md](HelmSetup.md#22-upgrade) for details.

### Uninstallation

```bash
helm uninstall devlake
```

**Warning**: This does not delete PersistentVolumeClaims. To completely remove data:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=devlake
```

## Configuration

### Database Options

#### MySQL (Default)

**Embedded MySQL**:
```yaml
database:
  type: mysql
  useExternal: false
  password: "strong-password"
  mysql:
    rootPassword: "strong-root-password"
```

**External MySQL** (AWS RDS, Cloud SQL, etc.):
```yaml
database:
  type: mysql
  useExternal: true
  externalServer: "db.example.com"
  externalPort: 3306
  username: "devlake"
  password: "strong-password"
  database: "lake"
```

#### PostgreSQL

**Embedded PostgreSQL**:
```yaml
database:
  type: postgresql
  useExternal: false
  externalPort: 5432
  password: "strong-password"
```

**External PostgreSQL**:
```yaml
database:
  type: postgresql
  useExternal: true
  externalServer: "postgres.example.com"
  externalPort: 5432
  username: "devlake"
  password: "strong-password"
  database: "lake"
```

**Important**: Grafana dashboards currently only support MySQL datasources. When using PostgreSQL, set `grafana.enabled=false` and provide an external Grafana instance via `grafana.external.url`, or use the UI without Grafana dashboards.

### Storage Configuration

**PersistentVolumeClaim** (Production):
```yaml
database:
  storage:
    type: pvc
    class: "fast-ssd"  # your storage class
    size: 50Gi
```

**HostPath** (Development only):
```yaml
database:
  storage:
    type: hostpath
    hostPath: /data/devlake
    size: 50Gi
```

### Security Configuration

#### External Secrets Operator

```yaml
option:
  externalSecrets:
    enabled: true
    secretStoreRef:
      name: vault-backend
      kind: SecretStore
```

#### Network Policies

```yaml
networkPolicy:
  enabled: true
  externalEgressCIDRs:
    - "192.30.252.0/22"  # GitHub API
    - "140.82.112.0/20"  # GitHub API
  ui:
    ingressNamespaceSelector:
      matchLabels:
        name: ingress-nginx
```

#### Image Digest Pinning

```yaml
imageDigests:
  lake: "sha256:abc123..."
  ui: "sha256:def456..."
```

## Deployment Scenarios

### NodePort (Simple Access)

```bash
helm install devlake devlake/devlake \
  --set service.type=NodePort \
  --set service.uiPort=30000 \
  --set database.password=<password> \
  --set database.mysql.rootPassword=<root-password> \
  --set lake.encryptionSecret.secret=$ENCRYPTION_SECRET
```

Access at: `http://<node-ip>:30000`

### Ingress (HTTP)

```bash
helm install devlake devlake/devlake \
  --set ingress.enabled=true \
  --set ingress.hostname=devlake.example.com \
  --set database.password=<password> \
  --set database.mysql.rootPassword=<root-password> \
  --set lake.encryptionSecret.secret=$ENCRYPTION_SECRET
```

Access at: `http://devlake.example.com`

### Ingress (HTTPS with TLS)

1. Create TLS secret:
```bash
kubectl create secret tls devlake-tls --cert=cert.pem --key=key.pem
```

2. Install with HTTPS:
```bash
helm install devlake devlake/devlake \
  --set ingress.enabled=true \
  --set ingress.enableHttps=true \
  --set ingress.hostname=devlake.example.com \
  --set ingress.tlsSecretName=devlake-tls \
  --set database.password=<password> \
  --set database.mysql.rootPassword=<root-password> \
  --set lake.encryptionSecret.secret=$ENCRYPTION_SECRET
```

Access at: `https://devlake.example.com`

### Gateway API HTTPRoute

For Kubernetes Gateway API integration:

```bash
helm install devlake devlake/devlake \
  --set httpRoute.enabled=true \
  --set httpRoute.gatewayName=my-gateway \
  --set httpRoute.gatewayNamespace=gateway-system \
  --set httpRoute.hostnames[0]=devlake.example.com \
  --set database.password=<password> \
  --set database.mysql.rootPassword=<root-password> \
  --set lake.encryptionSecret.secret=$ENCRYPTION_SECRET
```

**Configuration options**:
- `httpRoute.prefix`: Path prefix (default: `/`)
- `httpRoute.sectionName`: Gateway listener name (optional)
- `httpRoute.annotations`: Additional HTTPRoute annotations
- `httpRoute.extraPaths`: Additional path-based routes

Access at: `http://devlake.example.com` (HTTPS via Gateway TLS configuration)

### Production Deployment (Full Security)

```bash
helm install devlake devlake/devlake \
  --set database.type=mysql \
  --set database.password=$DB_PASSWORD \
  --set database.mysql.rootPassword=$DB_ROOT_PASSWORD \
  --set lake.encryptionSecret.secret=$ENCRYPTION_SECRET \
  --set networkPolicy.enabled=true \
  --set networkPolicy.externalEgressCIDRs='{0.0.0.0/0}' \
  --set lake.autoscaling.enabled=true \
  --set ui.autoscaling.enabled=true \
  --set ingress.enabled=true \
  --set ingress.enableHttps=true \
  --set ingress.hostname=devlake.example.com \
  --set ingress.tlsSecretName=devlake-tls \
  --set backup.enabled=true \
  --set backup.schedule="0 2 * * *"
```

## Operations

### Backup and Restore

#### Enable Automated Backups

```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"  # Daily at 2 AM UTC
  retentionDays: 7
  pvc:
    size: 10Gi
    storageClassName: "fast-ssd"
```

#### Manual Backup

**MySQL**:
```bash
kubectl exec -it devlake-mysql-0 -- mysqldump -uroot -p<root-password> lake > backup.sql
```

**PostgreSQL**:
```bash
kubectl exec -it devlake-postgresql-0 -- pg_dump -U merico lake > backup.sql
```

#### Restore

**MySQL**:
```bash
kubectl exec -i devlake-mysql-0 -- mysql -uroot -p<root-password> lake < backup.sql
```

**PostgreSQL**:
```bash
kubectl exec -i devlake-postgresql-0 -- psql -U merico -d lake < backup.sql
```

### Monitoring

#### Prometheus Metrics

```yaml
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring
    interval: 30s
```

#### Health Checks

DevLake includes built-in health probes:
- **Liveness**: `/ping` endpoint on port 8080
- **Readiness**: `/ping` endpoint with stricter thresholds
- **Database**: Type-specific probes (`mysqladmin ping` or `pg_isready`)

### Scaling

#### Horizontal Pod Autoscaling

```yaml
lake:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80

ui:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 5
    targetCPUUtilizationPercentage: 70
```

#### Multi-AZ Deployment

```yaml
lake:
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          devlakeComponent: lake

ui:
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          devlakeComponent: ui
```

## Development

### Local Development

1. **Clone repository**:
```bash
git clone https://github.com/apache/incubator-devlake-helm-chart.git
cd incubator-devlake-helm-chart
```

2. **Install dependencies**:
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm dependency update charts/devlake
```

3. **Validate chart**:
```bash
helm lint charts/devlake
```

4. **Test rendering**:
```bash
helm template test charts/devlake \
  --set database.password=test \
  --set database.mysql.rootPassword=test \
  --set lake.encryptionSecret.secret=$(openssl rand -base64 128)
```

5. **Run tests**:
```bash
helm install test charts/devlake \
  --set database.password=test \
  --set database.mysql.rootPassword=test \
  --set lake.encryptionSecret.secret=$(openssl rand -base64 128)

helm test test
```

### Contributing

Contributions welcome! This chart was originally created by [@matrixji](https://github.com/matrixji) with contributions from [@lshmouse](https://github.com/lshmouse), [@shubham-cmyk](https://github.com/shubham-cmyk), and [@SnowMoon-Dev](https://github.com/SnowMoon-Dev).

**Guidelines**:
- Follow [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- Maintain backward compatibility for minor versions
- Add tests for new features
- Update documentation


## License

Licensed under the [Apache License 2.0](LICENSE).

## Acknowledgments

Special thanks to the Apache DevLake community and all contributors who have helped improve this Helm chart.

**Original Contributors**:
- [@matrixji](https://github.com/matrixji) - Initial helm chart implementation
- [@lshmouse](https://github.com/lshmouse) - Helm deployment features
- [@shubham-cmyk](https://github.com/shubham-cmyk) - Configuration improvements
- [@SnowMoon-Dev](https://github.com/SnowMoon-Dev) - Bug fixes and enhancements

**Source**: This repository is derived from the `deployment/helm` directory in [apache/incubator-devlake](https://github.com/apache/incubator-devlake).

---

**Chart Version**: 2.0.0 | **App Version**: v1.0.3-beta12 | **Maintained by**: Apache DevLake Community
