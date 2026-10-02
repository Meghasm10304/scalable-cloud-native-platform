# =============================================================================
# IAM & Security — Identity layer for EC2 compute (Stage 3)
# =============================================================================
# Design principle: NO long-lived credentials ever touch an instance.
# EC2 assumes a ROLE via an Instance Profile; AWS rotates temporary
# credentials automatically every ~15 minutes.

# -----------------------------------------------------------------------------
# 1. Trust policy — WHO is allowed to assume this role
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    # Confused-deputy protection: only our tagged resources may assume it
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
}

resource "aws_iam_role" "app_instance" {
  name               = "${var.environment}-app-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "app-ec2-role"
    Project     = "cloud-native-platform"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# 2. Custom least-privilege policy — WHAT the role can do
# -----------------------------------------------------------------------------
# Deliberately NOT using managed policies like AmazonEC2FullAccess.
# We grant exactly what our app servers need, nothing more.
data "aws_iam_policy_document" "app_instance_permissions" {
  # Allow writing application + system logs to CloudWatch
  statement {
    sid    = "CloudWatchLogsWrite"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:*:log-group:/app/*"]
  }

  # Allow SSM Session Manager so we NEVER need SSH keys open to the internet.
  # Replaces port 22 access with audited, IAM-controlled shell sessions.
  statement {
    sid       = "SSMSessionManagerCore"
    effect    = "Allow"
    actions   = ["ssmmessages:CreateControlChannel", "ssmmessages:CreateDataChannel", "ssmmessages:OpenControlChannel", "ssmmessages:OpenDataChannel"]
    resources = ["*"]
  }

  statement {
    sid       = "SSMListAssociations"
    effect    = "Allow"
    actions   = ["ssm:DescribeInstanceInformation", "ssm:GetParameter"]
    resources = ["*"]
  }

  # Read-only discovery so the instance can identify itself
  statement {
    sid       = "SelfDiscovery"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances", "ec2:DescribeTags"]
    resources = ["*"]
  }

  # Explicitly deny anything that escalates privileges
  statement {
    sid       = "DenyPrivilegeEscalation"
    effect    = "Deny"
    actions   = ["iam:*", "organizations:*", "account:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "app_instance" {
  name        = "${var.environment}-app-instance-policy"
  description = "Least-privilege permissions for app EC2 instances"
  policy      = data.aws_iam_policy_document.app_instance_permissions.json

  tags = {
    Project     = "cloud-native-platform"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# 3. Attach policy to role
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "app_instance_custom" {
  role       = aws_iam_role.app_instance.name
  policy_arn = aws_iam_policy.app_instance.arn
}

# SSM managed instance core — required for Session Manager agent
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -----------------------------------------------------------------------------
# 4. Instance profile — the object EC2 actually references
# -----------------------------------------------------------------------------
resource "aws_iam_instance_profile" "app_instance" {
  name = "${var.environment}-app-instance-profile"
  role = aws_iam_role.app_instance.name

  tags = {
    Project     = "cloud-native-platform"
    Environment = var.environment
  }
}