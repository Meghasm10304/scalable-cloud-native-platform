#!/bin/bash
# =============================================================================
# Bootstrap script for CineSangeet EC2 instances
# Runs automatically on every new instance launched by the Auto Scaling Group
# =============================================================================

set -e

echo "=== CineSangeet Bootstrap Script ==="
echo "Started at: $(date)"

# -----------------------------------------------------------------------------
# 1. Update system packages
# -----------------------------------------------------------------------------
echo "[1/5] Updating system packages..."
apt update && apt upgrade -y
# -----------------------------------------------------------------------------
# 2. Install Node.js 20.x (LTS)
# -----------------------------------------------------------------------------
echo "[2/5] Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"
# -----------------------------------------------------------------------------
# 3. Install PM2 globally
# -----------------------------------------------------------------------------
echo "[3/5] Installing PM2..."
npm install -g pm2

# -----------------------------------------------------------------------------
# 4. Clone the application and install dependencies
# -----------------------------------------------------------------------------
echo "[4/5] Cloning application and installing dependencies..."

# Create home directory if it doesn't exist
if [ ! -d /home/ubuntu ]; then
  mkdir -p /home/ubuntu
  chown ubuntu:ubuntu /home/ubuntu
fi

su - ubuntu -c "
  cd /home/ubuntu
  if [ ! -d scalable-cloud-native-platform ]; then
    git clone https://github.com/Meghasm10304/scalable-cloud-native-platform.git
  fi
  cd scalable-cloud-native-platform
  git checkout main
  npm install --production
"

echo "Application directory ready"
ls -la /home/ubuntu/scalable-cloud-native-platform/

# -----------------------------------------------------------------------------
# 5. Start the application with PM2 and configure auto-start
# -----------------------------------------------------------------------------
echo "[5/5] Starting CineSangeet application..."

su - ubuntu -c "
  cd /home/ubuntu/scalable-cloud-native-platform

  # Stop any existing PM2 process (safety check)
  pm2 stop cine-app 2>/dev/null || true
  pm2 delete cine-app 2>/dev/null || true

  # Start the application
  pm2 start server.js --name cine-app

  # Save PM2 process list so it survives reboots
  pm2 save

  # Configure PM2 to start on system boot
  pm2 startup
"

echo "=== Bootstrap Complete ==="
echo "Application should be accessible on port 3000"
echo "Completed at: $(date)"