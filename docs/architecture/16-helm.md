# Stage 15 — Helm

## Overview

In this stage, the Kubernetes deployment is migrated from manually maintained YAML manifests to **Helm**.

Helm provides a package-management and templating mechanism for Kubernetes, allowing application resources to be grouped into a reusable **Helm Chart**. Configuration can then be customized through `values.yaml` or command-line overrides without modifying the underlying Kubernetes templates.

This stage introduces:

* Helm Charts
* Chart configuration
* Kubernetes templating
* Helm releases
* Configuration overrides
* Chart rendering and validation
* Upgrades
* Release history
* Rollbacks

---

## 🎯 Objective

The objective of this stage is to package the **CineSangeet** application as a Helm Chart and use Helm to manage its Kubernetes deployment lifecycle.

### Before Helm

Kubernetes resources are maintained as individual YAML files:

```text
deployment.yaml
service.yaml
hpa.yaml
```

Configuration changes require manually editing these manifests.

### After Helm

The application is packaged as a reusable chart:

```text
Helm Chart
    │
    ├── Deployment
    ├── Service
    └── HPA
```

Application configuration is centralized in:

```text
values.yaml
```

This allows the same chart to be deployed with different configurations for different environments.

---

# 🧠 Key Concepts

## Helm

**Helm** is a package manager for Kubernetes.

It simplifies the installation, configuration, upgrade, and rollback of Kubernetes applications.

---

## Helm Chart

A **Chart** is a collection of files that describes a Kubernetes application.

Example:

```text
cine-sangeet/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    └── hpa.yaml
```

---

## Release

A **Release** is a running instance of a Helm Chart inside a Kubernetes cluster.

For this project:

```text
Chart:
cine-sangeet

Release:
cine-sangeet
```

Multiple releases can be created from the same chart using different configurations.

---

## Values

Helm uses values to separate configuration from Kubernetes templates.

For example:

```yaml
replicaCount: 2

image:
  repository: meghasm10304/cinesangeet
  tag: v3
```

The values can be changed without modifying the deployment template.

Values can come from:

* `values.yaml`
* `--set`
* Additional values files

---

## Revision

Every Helm installation or upgrade creates a new **revision**.

Example:

```text
Revision 1 → Initial deployment
Revision 2 → Application upgrade
Revision 3 → Configuration change
```

Helm maintains this history so previous releases can be restored.

---

# 📦 Project Structure

The Helm chart is organized as follows:

```text
helm/
└── cine-sangeet/
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── deployment.yaml
        ├── service.yaml
        └── hpa.yaml
```

### File Responsibilities

| File              | Purpose                                |
| ----------------- | -------------------------------------- |
| `Chart.yaml`      | Chart metadata and application version |
| `values.yaml`     | Default application configuration      |
| `deployment.yaml` | Kubernetes Deployment template         |
| `service.yaml`    | Kubernetes Service template            |
| `hpa.yaml`        | Horizontal Pod Autoscaler template     |

---

# 🔧 Implementation

## 1. Install Helm

Download and install Helm:

```bash
curl -LO https://get.helm.sh/helm-v3.22.0-windows-amd64.tar.gz
tar -xzf helm-v3.22.0-windows-amd64.tar.gz
mv windows-amd64/helm.exe ~/bin/helm.exe
export PATH="$PATH:$HOME/bin"
```

Verify the installation:

```bash
helm version
```

Expected output should contain the installed Helm version.

---

# 2. Create the Helm Chart Structure

Create the chart directories:

```bash
mkdir -p helm/cine-sangeet/templates
cd helm/cine-sangeet
```

The resulting structure should be:

```text
cine-sangeet/
├── Chart.yaml
├── values.yaml
└── templates/
```

---

# 3. Create `Chart.yaml`

`Chart.yaml` contains the metadata for the Helm Chart.

```yaml
apiVersion: v2
name: cine-sangeet
description: CineSangeet movie & music app
version: 1.0.0
appVersion: "v3"
```

### Important Fields

| Field         | Description                               |
| ------------- | ----------------------------------------- |
| `apiVersion`  | Helm chart API version                    |
| `name`        | Name of the chart                         |
| `description` | Description of the application            |
| `version`     | Version of the Helm chart                 |
| `appVersion`  | Version of the application being deployed |

---

# 4. Configure `values.yaml`

Create the default configuration:

```yaml
replicaCount: 2

image:
  repository: meghasm10304/cinesangeet
  tag: v3

service:
  type: NodePort
  port: 80
  targetPort: 3000

resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "250m"

namespace: cine-sangeet
```

The `values.yaml` file acts as the central configuration layer for the chart.

For example:

```yaml
replicaCount: 2
```

can later be overridden without changing the template itself.

---

# 5. Create Kubernetes Templates

The Kubernetes resources are converted into Helm templates.

## Deployment

Create:

```text
templates/deployment.yaml
```

The Deployment template is responsible for:

* Creating application Pods
* Configuring the container image
* Setting replica count
* Configuring resource requests and limits
* Configuring health probes
* Injecting required configuration and secrets

---

## Service

Create:

```text
templates/service.yaml
```

The Service provides stable networking for the application Pods.

The configured service uses:

```yaml
type: NodePort
```

and forwards traffic to:

```text
Service Port: 80
Container Port: 3000
```

---

## Horizontal Pod Autoscaler

Create:

```text
templates/hpa.yaml
```

The HPA automatically adjusts the number of application Pods based on resource utilization.

The target configuration is:

```text
CPU Target: 50%
```

---

# 6. Validate the Chart

Before deploying the application, verify that the chart is valid:

```bash
helm lint .
```

A successful validation should report:

```text
1 chart(s) linted, 0 chart(s) failed
```

This catches common chart and template problems before deployment.

---

# 7. Render the Templates

Helm can render the templates locally without deploying anything to Kubernetes.

Run:

```bash
helm template test-release .
```

This generates the Kubernetes manifests that Helm would submit to the cluster.

This step is useful for verifying:

* Template syntax
* Generated Kubernetes YAML
* Values substitution
* Resource configuration
* Labels and selectors

---

# 8. Install the Helm Release

Deploy the application using Helm:

```bash
helm install cine-sangeet . \
  --namespace cine-sangeet
```

If the namespace does not already exist, it can be created with:

```bash
kubectl create namespace cine-sangeet
```

Verify the Helm release:

```bash
helm list -n cine-sangeet
```

Verify the Kubernetes resources:

```bash
kubectl get all -n cine-sangeet
```

---

# 9. Upgrade the Application

One of the major advantages of Helm is that configuration can be changed without manually editing multiple Kubernetes manifests.

For example, increase the application replicas from:

```text
2 → 3
```

using:

```bash
helm upgrade cine-sangeet . \
  --namespace cine-sangeet \
  --set replicaCount=3
```

Verify the deployment:

```bash
kubectl get deployment -n cine-sangeet
```

Verify the Pods:

```bash
kubectl get pods -n cine-sangeet
```

---

# 10. View Release History

Helm stores the history of deployments and upgrades.

Run:

```bash
helm history cine-sangeet -n cine-sangeet
```

Example:

```text
REVISION    STATUS
1           deployed
2           deployed
```

Each revision represents a different state of the Helm release.

---

# 11. Roll Back a Release

If an upgrade introduces a problem, Helm can restore a previous revision.

First, view the history:

```bash
helm history cine-sangeet -n cine-sangeet
```

Then roll back to revision `1`:

```bash
helm rollback cine-sangeet 1 \
  -n cine-sangeet
```

Verify the release:

```bash
helm status cine-sangeet -n cine-sangeet
```

And verify the Kubernetes resources:

```bash
kubectl get pods -n cine-sangeet
```

---

# 🔍 Useful Helm Commands

### List releases

```bash
helm list -n cine-sangeet
```

### Check release status

```bash
helm status cine-sangeet -n cine-sangeet
```

### Validate chart

```bash
helm lint .
```

### Render templates

```bash
helm template cine-sangeet .
```

### Install

```bash
helm install cine-sangeet . \
  --namespace cine-sangeet
```

### Upgrade

```bash
helm upgrade cine-sangeet . \
  --namespace cine-sangeet
```

### View history

```bash
helm history cine-sangeet \
  -n cine-sangeet
```

### Roll back

```bash
helm rollback cine-sangeet 1 \
  -n cine-sangeet
```

### Uninstall

```bash
helm uninstall cine-sangeet \
  -n cine-sangeet
```

---

# 🔄 Deployment Lifecycle

The Helm-based deployment lifecycle is:

```text
Developer
    │
    ▼
Application Code
    │
    ▼
Docker Image
    │
    ▼
Container Registry
    │
    ▼
Helm Chart
    │
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
          │
          ├── Deployment
          ├── Service
          └── HPA
    │
    ▼
Helm Install / Upgrade
    │
    ▼
Kubernetes Cluster
    │
    ▼
CineSangeet Application
```

---

# 🆚 Before vs After Helm

| Without Helm                            | With Helm                                    |
| --------------------------------------- | -------------------------------------------- |
| Multiple YAML files managed manually    | Resources packaged as a Chart                |
| Configuration mixed with manifests      | Configuration separated into `values.yaml`   |
| Manual changes required for deployments | Values can be overridden                     |
| Upgrades require managing manifests     | `helm upgrade`                               |
| Rollback requires manual recovery       | `helm rollback`                              |
| No built-in release history             | Helm maintains revisions                     |
| Difficult to reuse across environments  | Same chart can support multiple environments |

---
