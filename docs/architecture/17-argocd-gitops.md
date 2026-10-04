# Stage 16 — GitOps with Argo CD

## 🎯 Goal
Implement GitOps continuous delivery so that the Kubernetes cluster is automatically reconciled with the desired state declared in Git, instead of deploying manually with `kubectl apply`.

---

## 🧠 What is GitOps?

**Traditional deployment:**
Developer → kubectl apply → Cluster

The cluster state lives only in someone's terminal history. Nobody knows what's actually running.

**GitOps:**
Developer → git push → Git (source of truth) → Argo CD watches → Cluster syncs automatically

Git becomes the **single source of truth**. The cluster continuously converges toward whatever is committed in Git.

**Argo CD** is a GitOps controller. It constantly compares:
- **Desired state** → what's in Git (`helm/cine-sangeet`)
- **Live state** → what's actually running in the cluster

If they differ, it reports `OutOfSync` and (with auto-sync enabled) fixes it.

---

## 🛠️ What We Did

### 1. Installed Argo CD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
Accessed the UI locally:

bash

Copy
kubectl port-forward svc/argocd-server -n argocd 8080:443
# https://localhost:8080  (self-signed cert warning is expected)
Retrieved the initial admin password:

bash

Copy
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
Note: An error appeared for applicationsets.argoproj.io ("Too long: may not be more than 262144 bytes"). This is a non-critical CRD annotation issue affecting an optional feature — core Argo CD installed fine.

2. Created the Application declaratively
Instead of using the argocd CLI (not installed), we defined the Application as a Kubernetes custom resource:

yaml

Copy
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cine-sangeet
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Meghasm10304/scalable-cloud-native-platform.git
    targetRevision: main
    path: helm/cine-sangeet          # our Helm chart from Stage 15
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: cine-sangeet
  syncPolicy:
    automated:
      prune: true       # delete resources removed from Git
      selfHeal: true    # revert manual changes made to the cluster
EOF
Key fields:

source.path
Tells Argo CD which folder in Git holds the manifests/chart
targetRevision
Branch/tag/commit to track (main)
destination.server
https://kubernetes.default.svc = the same cluster Argo CD runs in
automated.prune
If you delete a manifest from Git, Argo CD deletes it from the cluster
automated.selfHeal
If someone edits the cluster by hand, Argo CD reverts it
3. Fixed a real bug through Git (the proper way)
A pod was stuck in ImagePullBackOff:

Failed to pull image "meghams10304/cinesangeet:v3":
pull access denied, repository does not exist or may require authorization
Root cause: typo in the image repository — meghams10304 instead of meghasm10304.

Two things had to be fixed:

Corrected the typo in helm/cine-sangeet/values.yaml, committed & pushed.
Removed the hard-coded --helm-set override parameters from the Application, because overrides take priority over values.yaml — otherwise Git would never win.
bash

Copy
kubectl patch application cine-sangeet -n argocd --type='json' \
  -p='[{"op": "remove", "path": "/spec/source/helm/parameters"}]'
Result: Synced + Healthy, broken pod garbage-collected.

4. Demo 1 — Scale via Git only
Changed replicaCount: 2 → 4 in values.yaml, then:

bash

Copy
git add helm/cine-sangeet/values.yaml
git commit -m "chore: scale cine-sangeet to 4 replicas via GitOps"
git push origin main
No kubectl apply. Argo CD detected the new commit and scaled the Deployment on its own:

deployment.apps/cine-sangeet-app   4/4   4   4
5. Demo 2 — Drift detection + self-healing
Manually broke the desired state:

bash

Copy
kubectl scale deployment cine-sangeet-app -n cine-sangeet --replicas=3
Within seconds Argo CD reverted it back to 4/4, staying Synced. Manual cluster edits cannot survive — Git always wins.