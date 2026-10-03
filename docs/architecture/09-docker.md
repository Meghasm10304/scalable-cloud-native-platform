# 08 — Dockerization

## What
Containerized CineSangeet using a multi-stage Dockerfile, exposing port 3000 and running as a non-root user.
s
## Why
- Portability: Run CineSangeet anywhere Docker is available, not just on the specific EC2 instance.
- Consistency: Same runtime environment locally and in production.
- Security: Non-root user and minimal image reduce attack surface.
- Scalability: Docker images can be pushed to a registry and deployed to ECS/EKS.

## How
- Created multi-stage Dockerfile:
  - Stage 1 (builder): `node:24-alpine`, install production dependencies via `npm ci --omit=dev`
  - Stage 2 (runtime): `