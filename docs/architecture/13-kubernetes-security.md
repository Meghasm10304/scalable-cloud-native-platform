## Stage 12 — Kubernetes Configuration & Security

### 🎯 Goal
Implement secure configuration management and access control. This involves separating sensitive data (Secrets) from application code and enforcing least-privilege access (RBAC).

### 🧠 What Was Learned
- **Secrets**: Kubernetes objects used to store sensitive information like API keys. Unlike ConfigMaps, these are base64 encoded (though not encrypted by default, so RBAC is critical).
- **ServiceAccounts**: Identities for Pods. By default, Pods use the "default" service account which might have too many permissions. We created a dedicated one.
- **RBAC (Role-Based Access Control)**:
  - **Role**: Defines *what* actions are allowed (e.g., `get`, `list`) on *which* resources (e.g., `pods`).
  - **RoleBinding**: Grants those permissions to a specific user or ServiceAccount.
- **Least Privilege Principle**: Giving the application only the minimum permissions necessary to function. If the container is compromised, the attacker cannot delete other services or access other namespaces.

### 🛠️ Tools Used
- `kubectl`
- Kubernetes RBAC API

### 📦 Artifacts Created
1. **Secret**: `cine-sangeet-secrets` (TMDB_API_KEY, LASTFM_KEY)
2. **ServiceAccount**: `cine-sangeet-sa`
3. **Role**: `cine-sangeet-role` (Verbs: get, list, watch; Resources: pods, services)
4. **RoleBinding**: `cine-sangeet-rolebinding`

### 🔧 Implementation Steps

**1. Create Secret (Sensitive Data):**
We moved API keys out of `server.js` and into Kubernetes Secrets.
```bash
kubectl create secret generic cine-sangeet-secrets \
  --namespace=cine-sangeet \
  --from-literal=TMDB_API_KEY=<KEY> \
  --from-literal=LASTFM_KEY=<KEY>