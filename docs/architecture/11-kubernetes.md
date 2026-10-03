# Stage 10 — Kubernetes Fundamentals

## Goal
Understand Kubernetes basics without paying AWS costs.

## What Was Done
- Installed Minikube with Docker driver
- Created cluster (Kubernetes v1.37.0)
- Created namespace `cine-sangeet`
- Created a manual pod (`nginx-test`)
- Created a Deployment (`web`) with 3 replicas
- Scaled deployment to 5 replicas
- Deleted a pod and observed Kubernetes self-healing

## Key Concepts Learned
- **Namespace**: Logical isolation (cine-sangeet)
- **Pod**: Smallest deployable unit (container wrapper)
- **Deployment**: Manages replica count, rolling updates, rollbacks
- **ReplicaSet**: Ensures the correct number of pod replicas exist
- **Self-Healing**: Kubernetes recreates deleted/failed pods automatically
- **kubectl**: The CLI tool for all Kubernetes operations

## Commands Used
minikube start --driver=docker
kubectl get nodes
kubectl create namespace cine-sangeet
kubectl run nginx-test --image=nginx --namespace=cine-sangeet
kubectl describe pod nginx-test -n cine-sangeet
kubectl create deployment web --image=nginx --replicas=3 -n cine-sangeet
kubectl get replicasets -n cine-sangeet
kubectl scale deployment web --replicas=5 -n cine-sangeet
