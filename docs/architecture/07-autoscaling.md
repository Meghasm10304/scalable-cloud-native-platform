# Stage 6 — Auto Scaling Group (ASG)

## 🎯 Goal
Automatically adjust EC2 capacity based on demand, and keep the application available
across multiple Availability Zones so a single instance or AZ failure does not cause downtime.

## 🧠 What I learned
- Launch Templates define the blueprint (AMI, instance type, user_data, SG, IAM profile).
- An ASG manages a fleet of instances from a launch template: min / desired / max.
- `target_group_arns` is what links an ASG to an ALB target group. Without it, instances
  launch but receive ZERO traffic.
- `health_check_type = "ELB"` makes the ASG trust the load balancer's HTTP health check,
  not just the EC2 instance status check.
- `health_check_grace_period` gives user_data time to install/start the app before the
  ASG judges the instance unhealthy.
- `vpc_zone_identifier` must include subnets in MULTIPLE AZs for real HA.
- Instance refresh performs rolling replacement when the launch template changes.

## 🛠️ Tools / Services
AWS Auto Scaling, Launch Template, EC2, Application Load Balancer, Target Group, Terraform.

## 📦 What I created
- aws_launch_template.app (lt-0c982535703d3c23e)
- aws_autoscaling_group.app (learning-cinesangeet-asg) min=2 desired=2 max=3
- aws_autoscaling_policy.scale_out / scale_in
- Bootstrap script (user_data) installing Node.js 20 + PM2 + CineSangeet app

## ✅ Final verified state
| Check | Result |
|---|---|
| Instance refresh | Successful |
| Running instances | 2 |
| AZ distribution | ap-south-1a + ap-south-1b |
| Target health | both healthy |
| End-to-end curl | HTTP 200 |

## 🔧 Problems faced & fixes

### Problem 1 — Target group showed no targets
Symptom: describe-target-health returned rows with null values; ASG had running instances.
Root cause: needed to confirm target_group_arns was attached to the ASG.
Verification: describe-auto-scaling-groups showed TG ARN correctly attached → not the bug.
Lesson: verify attachment before assuming misconfiguration.

### Problem 2 — AWS CLI printed None for every health field (biggest time sink)
Symptom: TargetHealthDescriptions[*].[Target.Id,State.HealthState] → all None.
Tried: State.Code, TargetHealth.Code → still None.
Root cause: wrong nested key name. The real API shape is TargetHealth.State.
Fix: dumped raw JSON (--output json) and read actual keys instead of guessing JMESPath.
Lesson: when a query returns nulls, inspect the raw response. Trust end-to-end curl over tool output.

### Problem 3 — All new instances FailedHealthChecks
Symptom: fresh instances registered but ELB marked them unhealthy; curl worked only via
stale/older instances.
Diagnosis: SSM Send-Command reading /var/log/cloud-init-output.log showed:
  line 16: yum: command not found
  Failed to run module scripts_user
Root cause: AMI is Ubuntu 22.04 (apt/dpkg) but bootstrap script used RHEL commands (yum,
rpm.nodesource.com). Script aborted at step 1/5, so Node.js/app never installed.
Fix: apt update && apt upgrade -y ; deb.nodesource.com/setup_20.x ; apt install -y nodejs
Then aws autoscaling start-instance-refresh to roll all instances onto LT v2.
Lesson: always match package manager to the AMI family. Read cloud-init logs first.

### Problem 4 — Orphan / ghost targets in target group
Symptom: target group listed instances that were no longer ASG members (draining forever).
Cause: manual register-targets earlier + terminated instances mid-deregistration.
Fix: aws elbv2 deregister-targets for stale IDs; ASG auto-manages its own members.
Lesson: never manually register targets on an ASG-managed target group — the ASG owns them.
