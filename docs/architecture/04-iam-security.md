# IAM & Security Model

## Goal
Give EC2 instances only the permissions they need, with no permanent keys and no SSH open to the internet.

## How It Works
EC2 does not store access keys. Instead it assumes an **IAM Role** through an **Instance Profile**. AWS issues temporary credentials and rotates them automatically. If a key is ever leaked, it expires on its own.

## Resources Created
| Resource | Name | Purpose |
|---|---|---|
| IAM Role | app-ec2-role | Assumed by application instances |
| IAM Policy | app-instance-policy | Custom least-privilege rules |
| Managed Policy | AmazonSSMManagedInstanceCore | Enables Session Manager |
| Instance Profile | app-instance-profile | Attaches the role to EC2 |

## Trust Policy
Only the EC2 service can assume this role, limited to our region:
- Principal: `ec2.amazonaws.com`
- Condition: region must equal our deployment region

This stops any other service or account from borrowing these permissions.

## Permissions Granted
| Permission | Scope | Reason |
|---|---|---|
| CloudWatch Logs write | Only log groups under `/app/*` | Ship application logs |
| SSM Session Manager | Required actions | Shell access without SSH |
| SSM describe / get parameter | Read only | Agent registration and config |
| EC2 describe instances and tags | Read only | Instance identifies itself |

## Explicit Deny
The policy denies `iam:*`, `organizations:*`, and `account:*`. A deny always
overrides an allow, so even if a broad policy is attached later, the instance
cannot change its own permissions.

## Security Groups
| Group | Inbound | Source |
|---|---|---|
| web | Port 80 | Internet |
| app | Port 3000 | Web group only |
| app | Port 22 | Admin staging group only |
| admin staging | None inline | Updated by pipeline |

Traffic flows Internet → web → app. Each layer only accepts from the layer above
it. Rules reference security group IDs instead of IP ranges, so they survive IP changes.

## Verification
- Role trust policy confirmed for EC2 service in our region
- Only two policies attached; no administrator or full EC2 access
- No inline policies; everything is managed in Terraform
- Instance profile correctly linked to the role

## Decisions Not Made
- No administrator or wildcard EC2 policies
- No hard-coded credentials in the repository
- No SSH open to the whole internet
- No manual IAM changes outside Terraform

## Next Stage
Stage 4 launches EC2 instances using this instance profile, so credentials are
available immediately with no extra configuration.
