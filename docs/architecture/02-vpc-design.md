# VPC Design Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Design Decisions](#design-decisions)
4. [Security Groups](#security-groups)
5. [Created Resources](#created-resources)
6. [Cost Analysis](#cost-analysis)
7. [Problems Faced & Solutions](#problems-faced--solutions)
8. [Operations Guide](#operations-guide)
9. [Interview Preparation](#interview-preparation)

---

## Overview

**Project:** Scalable Cloud-Native Application Platform  
**Stage:** AWS Networking (VPC)  
**Region:** ap-south-1 (Mumbai)  
**Terraform Module:** `infrastructure/networking/`  
**Status:** ✅ Applied — 15 resources created successfully

This VPC is the network foundation for all subsequent infrastructure. It implements a production-grade multi-AZ topology separating public and private tiers to enforce security boundaries and enable high availability.

---

## Architecture

### Addressing Plan

| Resource | CIDR Block | AZ | Purpose |
|----------|------------|----|---------| 
| **VPC** | 10.0.0.0/16 | - | Private network space (65,536 IPs) |
| app-vpc-public-a | 10.0.0.0/24 | ap-south-1a | Load balancer tier |
| app-vpc-public-b | 10.0.1.0/24 | ap-south-1b | Load balancer tier |
| app-vpc-private-a | 10.0.10.0/24 | ap-south-1a | EC2 application servers |
| app-vpc-private-b | 10.0.11.0/24 | ap-south-1b | EC2 application servers |

Each `/24` subnet provides 251 usable addresses (AWS reserves 5). The gaps between ranges (`10.0.2.0/24` through `10.0.9.0/24`) are intentionally left unallocated for future workloads like EKS pod networks.

### Network Topology

```text
                    Internet
                        │
                 ┌──────┴──────┐
                 │ Internet GW │
                 └──────┬──────┘
        ┌───────────────┴────────────────┐
        │      VPC: 10.0.0.0/16          │
        │                                │
        │  ap-south-1a         ap-south-1b│
        │  ┌───────────┐    ┌─────────┐  │
        │  │ public-a  │    │pub-b    │  │  ← ALB lives here (Stage 5)
        │  │10.0.0.0/24│    │10.0.1/24│  │     Route: 0.0.0.0/0 → IGW
        │  ├───────────┤    ├─────────┤  │
        │  │ private-a │    │priv-b   │  │  ← EC2 lives here (Stage 4)
        │  │10.0.10/24 │    │10.0.11  │  │     No internet route
        │  └───────────┘    └─────────┘  │
        └────────────────────────────────┘

```

## AWS Networking — Design Decisions & Security Model

### Why Two Availability Zones?

**Decision:** Deploy subnets across `ap-south-1a` and `ap-south-1b`.

**Reasoning:**
- **High availability:** If one AZ experiences failure, the other continues serving traffic.
- **Hard requirement:** ALB and Auto Scaling groups require at least two AZs.
- **Fault isolation:** Data centers are physically separate; power or cooling failure in one doesn't affect the other.

**Trade-off:** None. Two AZs cost nothing extra and provide substantial resilience benefits.

---

### Why Public and Private Subnets?

**Decision:** Separate subnets into public (internet-reachable) and private (isolated) tiers.

**Public subnets:**
- Have a route to the Internet Gateway (`0.0.0.0/0 → igw-...`).
- Host resources that must be directly reachable from the internet (ALB).
- `map_public_ip_on_launch = true` so instances automatically receive public IPv4 addresses.

**Private subnets:**
- No route to the internet (no `0.0.0.0/0` entry in their route table).
- Application servers live here. They receive traffic only through the load balancer.
- Never directly addressable from outside the VPC.
- `map_public_ip_on_launch = false` to prevent accidental exposure.

**Why it matters:** This separation means even if an attacker compromises the load balancer, they cannot directly reach your application servers. The blast radius is contained.

---

### What Actually Makes a Subnet "Public"?

**Critical insight:** Naming a subnet `public-subnet` does **nothing**. Routing determines whether a subnet is public or private.

The public route table contains:

```text
Destination    Target
0.0.0.0/0      igw-0e7ca6cc0d7d187bb        
```