# Project Architecture

## 1. Problem Statement
As applications grow, manually managing servers and deployments becomes difficult. 
This project demonstrates the evolution from a simple application to a scalable, 
cloud-native platform using AWS, Docker, and Kubernetes.

## 2. Current Architecture (Stage 0)
- **Application:** Node.js Express Server
- **Frontend:** Static HTML/CSS/JS
- **Deployment:** Local development machine
- **Goal:** Verify the application runs correctly before cloud deployment.

## 3. Future Architecture (End State)
- **Infrastructure:** AWS (VPC, EC2, ALB, Auto Scaling)
- **Containerization:** Docker
- **Orchestration:** Kubernetes (EKS)
- **CI/CD:** Argo CD (GitOps)
- **Observability:** Prometheus, Grafana, Loki

## 4. Technology Stack
- **Cloud:** AWS
- **Container:** Docker
- **Orchestration:** Kubernetes, Helm, Argo CD
- **Monitoring:** Prometheus, Grafana
- **Language:** Node.js

## 5. Architecture Diagram
![Project Architecture](cloud-native-platform-architecture.png.png)