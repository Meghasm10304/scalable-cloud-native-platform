# Stage 9 — Container Registry

## Goal
Store the Docker image in a remote registry so Kubernetes can pull it.

## What Was Done
- Logged into Docker Hub via browser-based auth
- Tagged local image: cinesangeet:v3 → meghasm10304/cinesangeet:v3
- Pushed image to Docker Hub
- Pulled image back to verify integrity

## Commands Used
docker login
docker tag cinesangeet:v3 meghasm10304/cinesangeet:v3
docker push meghasm10304/cinesangeet:v3
docker pull meghasm10304/cinesangeet:v3

## Verification
Push digest: sha256:2da163c2ed78b6fb0c8aff4bd2249657d842396a175e8297353ec6bf3996292f
Pull result: Image is up to date — digest matches.

## Why This Matters
Kubernetes clusters cannot access images that exist only on a local machine.
A registry acts as the single source of truth for container images across environments.

## Image Lifecycle Understood
Build locally → Tag with registry path → Push → Registry stores → Cluster pulls by tag/digest

## Interview Questions
Q: Why not just use localhost images in Kubernetes?
A: K8s nodes are separate machines. They need a network-accessible registry to pull images.

Q: What's the difference between a tag and a digest?
A: A tag (v3) is mutable and can be overwritten. A digest (sha256:...) is immutable content addressing. Production deployments should pin digests.

Q: Why did you use Docker Hub instead of ECR?
A: Docker Hub is free and sufficient for learning. ECR will be introduced as an AWS-specific extension later since it integrates with IAM and VPC endpoints.