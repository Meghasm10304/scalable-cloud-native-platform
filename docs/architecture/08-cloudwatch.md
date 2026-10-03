# Stage 7 — CloudWatch Monitoring

**Date:** 3 October 2026
**Terraform:** `infrastructure/monitoring/`
**Region:** ap-south-1 (Mumbai)

---

## What → Why → How

### What I built
Two CloudWatch metric alarms and one unified dashboard, all provisioned through
Terraform, monitoring the EC2/ALB layer created in Stages 4–6.

| Resource | Name | Purpose |
|---|---|---|
| Alarm | `learning-cinesangeet-asg-cpu-high` | Fires when ASG avg CPU > 70% over 2×5-min periods |
| Alarm | `learning-cinesangeet-asg-unhealthy-targets` | Fires when any ALB target becomes unhealthy |
| Dashboard | `learning-cinesangeet-asg-dashboard` | 4 widgets: EC2 CPU, ALB Unhealthy Host Count, ALB Request Count, ALB Healthy Host Count |

### Why this stage exists
Stages 4–6 made the platform *work*. Stage 7 makes it *visible*. Without metrics
and alarms, an outage between deploys is invisible — and autoscaling decisions
are being taken on data nobody is watching.

### How I did it
Rather than importing resources from earlier stages' Terraform state, I used
**data sources** to read existing AWS objects by name at plan time:

```hcl
data "aws_lb" "app"               { name = var.alb_name }
data "aws_autoscaling_group" "app" { name = var.asg_name }
data "aws_lb_target_group" "app"   { name = var.tg_name }