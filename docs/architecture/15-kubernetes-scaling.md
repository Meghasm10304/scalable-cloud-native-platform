# Stage 14 — Kubernetes Scaling & Reliability

## Goal
Demonstrate why Kubernetes orchestration goes beyond simply running Docker containers.

## What Was Done
- Added startup, readiness, and liveness probes to the Deployment
- Set resource requests and limits for predictable scheduling
- Enabled metrics-server addon
- Created a HorizontalPodAutoscaler (HPA) targeting 50% CPU
- Verified self-healing by deleting a pod

## Probes Explained
| Probe | Purpose | When It Runs |
|-------|---------|--------------|
| Startup | Waits for slow-starting apps before other probes activate | First, until success |
| Readiness | Decides if pod receives traffic from Service | Continuously after startup |
| Liveness | Detects deadlocked/crashed containers and restarts them | Continuously after startup |

Our health endpoint `/api/health` returns `secretsLoaded: true`, making it a perfect probe target — it fails fast if configuration is missing.

## Resource Management
```yaml
resources:
  requests:      # Scheduler uses this to place pods
    memory: "64Mi"
    cpu: "100m"
  limits:        # Hard ceiling; exceeding CPU throttles, memory OOM-kills
    memory: "128Mi"
    cpu: "250m"