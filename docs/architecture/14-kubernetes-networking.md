# Stage 13 — Kubernetes Networking

## Goal
Understand how users and services communicate with applications inside Kubernetes, and route external traffic through an Ingress.

## What Was Done
- Enabled the Nginx Ingress Controller via `minikube addons enable ingress`
- Created an Ingress resource with host-based routing (`cine-sangeet.local`)
- Ran `minikube tunnel` to expose the Ingress externally on Windows
- Verified end-to-end routing: User → Ingress → Service → Pods

## Service Types Explained
| Type | Use Case | Reachability |
|------|----------|--------------|
| ClusterIP | Default; internal pod-to-pod communication | Inside cluster only |
| NodePort | Exposes service on every node's static port | Node IP + port |
| LoadBalancer | Cloud provider provisions a real load balancer | External (cloud) |
| Ingress | HTTP routing by host/path, single entry point | External via controller |

## DNS & Service Discovery
Kubernetes assigns each Service a stable DNS name:

    <service>.<namespace>.svc.cluster.local

Example: `cine-sangeet-service.cine-sangeet.svc.cluster.local`

Pods resolve this automatically via CoreDNS — no hardcoded IPs needed. This is why moving apps between environments requires zero config changes.

## Commands Used
minikube addons enable ingress
kubectl wait --namespace=ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
minikube tunnel
kubectl apply -f k8s/ingress.yaml
kubectl get ingress -n cine-sangeet
curl -v http://localhost/api/health -H "Host: cine-sangeet.local"

## Verification Result
HTTP/1.1 200 OK
{"status":"ok","timestamp":"...","secretsLoaded":true}

## Troubleshooting Faced
Problem: curl to minikube IP (192.168.49.2:80) returned empty response.
Cause: On Windows, ports below 1024 require elevated privileges, and the Docker driver network isn't directly routable from the host.
Fix: Use `http://localhost` instead of the minikube IP while `minikube tunnel` is running. The tunnel forwards localhost:80 into the cluster.

