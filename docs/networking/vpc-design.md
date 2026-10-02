# VPC Design

## Architecture Overview

This VPC provides the network foundation for the Scalable Cloud-Native Application Platform. It implements a production-style multi-AZ topology with public and private subnets.

## Addressing Plan

| Resource | CIDR | AZ | Purpose |
|----------|------|----|---------| 
| VPC | 10.0.0.0/16 | — | Entire private network |
| app-vpc-public-a | 10.0.0.0/24 | ap-south-1a | Load balancer (ALB) |
| app-vpc-public-b | 10.0.1.0/24 | ap-south-1b | Load balancer (ALB) |
| app-vpc-private-a | 10.0.10.0/24 | ap-south-1a | EC2 application servers |
| app-vpc-private-b | 10.0.11.0/24 | ap-south-1b | EC2 application servers |

## Design Decisions

### Why two Availability Zones?
High availability. If one AZ experiences failure, the other continues serving traffic. Required for ALB and Auto Scaling groups.

### Why public and private subnets?
- **Public subnets**: Resources here have direct routes to the internet via Internet Gateway. Used for the load balancer, which must be reachable by users.
- **Private subnets**: No direct internet route. Application servers live here. They receive traffic through the load balancer and are not directly accessible from the internet.

### Why separate route tables?
Route tables determine whether a subnet is public or private. The public route table has `0.0.0.0/0 → IGW`. The private route table has no internet route (for now).

### Security group strategy
- **sg-web**: Accepts HTTP (port 80) from anywhere. This is what faces the internet.
- **sg-app**: Accepts port 3000 (Node.js app) only from instances in `sg-web`. Identity-based, not IP-based. SSH (port 22) restricted to `sg-security-hub`, which is currently empty.

### Known trade-off
We use one shared private route table for both AZs. Production would use one per AZ (each pointing to that AZ's NAT gateway) so a NAT failure in one AZ doesn't affect the other. We'll revisit this when we add NAT.

## Cost Notes

**Free resources:**
- VPC
- Subnets
- Route tables
- Internet Gateway
- Security groups

**Not created yet (intentionally):**
- NAT Gateway: costs ~$33/month. Will add only when EC2 moves to private subnets.

## How to Deploy

```bash
cd infrastructure/networking
terraform init
terraform plan
terraform apply
``` 

## How to Destroy
```bash 
cd infrastructure/networking
terraform destroy
```
All resources in this directory can be destroyed safely without affecting other project components.

