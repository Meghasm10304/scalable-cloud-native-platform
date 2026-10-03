## Stage 11 — Kubernetes Application Deployment

### 🎯 Goal
Deploy the actual CineSangeet application into the local Kubernetes cluster using the Docker image pushed to Docker Hub.

### 🧠 What Was Learned
- **Deployment**: How to manage application replicas and updates declaratively.
- **Service (NodePort)**: How to expose internal pods to external traffic.
- **Secrets Injection**: How to inject sensitive environment variables securely without hardcoding them in YAML.
- **Minikube Tunneling**: Accessing NodePort services on Windows/Docker driver environments.

### 🛠️ Tools Used
- Minikube (Local Cluster)
- kubectl
- Docker Hub Image: `meghasm10304/cinesangeet:v3`

### 📦 Artifacts Created
1. `k8s/deployment.yaml`: Defines the app, image, port, and secret references.
2. `k8s/service.yaml`: Exposes the app via NodePort (30080).
3. **Kubernetes Secret**: `cine-sangeet-secrets` (created via CLI, not committed to Git).

### 🔧 Implementation Steps

**1. Create Secret (Securely via CLI):**
```bash
kubectl create secret generic cine-sangeet-secrets \
  --namespace=cine-sangeet \
  --from-literal=TMDB_API_KEY=<YOUR_KEY> \
  --from-literal=LASTFM_KEY=<YOUR_KEY>