# Load Balancer Design Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Design Decisions](#design-decisions)
4. [Security Model](#security-model)
5. [Created Resources](#created-resources)
6. [Cost Analysis](#cost-analysis)
7. [Problems Faced & Solutions](#problems-faced--solutions)
8. [Operations Guide](#operations-guide)
9. [Interview Preparation](#interview-preparation)

---

## Overview

**Project:** Scalable Cloud-Native Application Platform  
**Stage:** 5 — Application Load Balancer (ALB)  
**Region:** ap-south-1 (Mumbai)  
**Terraform Root:** `infrastructure/load-balancer/`  
**Status:** ✅ Applied — 4 resources created successfully  

This stage introduces an Application Load Balancer in front of the existing EC2 instance, establishing the traffic path that will later support Auto Scaling Groups in Stage 6. The ALB sits in public subnets and forwards traffic to the application running on port 3000 through a target group with health checking.

---

## Architecture

### Traffic Flow

```text
                        Internet
                           │
                    ┌──────┴──────┐
                    │   HTTP :80  │
                    │     ALB     │  ← web SG (port 80, 443 from 0.0.0.0/0)
                    │  (public)   │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │    Target Group :3000    │
              │  Health Check: / → 200   │
              └────────────┬────────────┘
                           │
              ┌────────────┴────────────┐
              │   EC2 Instance :3000     │  ← app SG (port 3000 from web SG only)
              │   CineSangeet Node.js    │
              └─────────────────────────┘
```

## Subnet Placement
```text
Resource: ALB
Subnet: app-vpc-public-a
AZ: ap-south-1a
CIDR: 10.0.0.0/24
Purpose: Internet-facing entry point

Resource: ALB
Subnet: app-vpc-public-b
AZ: ap-south-1b
CIDR: 10.0.1.0/24
Purpose: Multi-AZ high availability

Resource: EC2
Subnet: app-vpc-public-a
AZ: ap-south-1a
CIDR: 10.0.0.0/24
Purpose: Application server (to be moved private in Stage 6)
```

Note: The EC2 is currently in a public subnet for administrative simplicity. Stage 6 will move it to private subnets once a NAT Gateway is added.

## Security Group Relationships
```text
sg: web (sg-036a400233a256306)
Attached To: ALB
Inbound Rules: Port 80, 443 from 0.0.0.0/0
Role: Internet-facing tier

sg: app (sg-0f1554301b0c0ea3e)
Attached To: EC2
Inbound Rules: Port 3000 from web SG; Port 22 from security-hub SG
Role:Application tier

sg: security-hub (sg-0c939b403fa3868fb)
Attached To: Bastion/Admin
Inbound Rules: (Managed separately)
Role: Administrative access
```

The key security property: port 3000 is never exposed to the internet. Only traffic originating from the ALB (identified by its web security group) can reach the application.

### Design Decisions

## Why an Application Load Balancer (not Network LB or Classic)?
Decision: Use ALB (Layer 7).

Reasoning:

Path-based routing: Future stages may route /api vs /static to different targets.
HTTP health checks: ALB understands HTTP status codes, enabling intelligent target management.
Target group abstraction: Decouples the load balancer from backend instances, making Stage 6 (ASG integration) seamless.
Cost efficiency: ALB is pay-per-hour + per-processed-data, appropriate for low-traffic learning environments.
Trade-off: ALB adds ~0.0225/hour( 16/month). Acceptable for the architectural benefits.

## Why Reuse Existing Security Groups (Not Create New Ones)?
Decision: Attach the existing web SG to the ALB; keep app SG on EC2.

Reasoning:

The networking Terraform already designed these groups with correct rules.
Creating new SGs would fragment the security model and make auditing harder.
The app SG already has the exact rule we need: TCP 3000 from web SG reference.
Result: Zero new security groups created. The architecture matches the documentation exactly.

## Why Use Data Sources Instead of Remote State?
Decision: Look up VPC, subnets, SGs, and EC2 by tag name using data sources.

Reasoning:

Keeps Terraform roots independent — no state file coupling between networking/, compute/, and load-balancer/.
If one root is destroyed and recreated, the others don't break.
Tag-based lookup is human-readable and debuggable.
Trade-off: Slight risk if tags are accidentally changed. Mitigated by consistent naming conventions enforced across all roots.

## Why Register EC2 via aws_lb_target_group_attachment (Not Inline)?
Decision: Use a separate attachment resource referencing the EC2 via data source.

Reasoning:

The EC2 is owned by the compute/ Terraform root. The load-balancer/ root must not attempt to manage it.
Cross-root references via data sources prevent state conflicts.
When Stage 6 replaces EC2 with an ASG, this attachment gets replaced by target_group_arns on the ASG itself.

## Why Health Check Path / Instead of /health?
Decision: Use / as the health check path with matcher 200.

Reasoning:

The application returns a full HTML page at / with status 200 when healthy.
A dedicated /health endpoint would require application code changes.
For Stage 5, verifying the main page loads is sufficient proof the app is serving traffic.
Future improvement: Add a lightweight /health endpoint that returns JSON without database calls, reducing health-check overhead.