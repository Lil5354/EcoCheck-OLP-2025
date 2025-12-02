#!/bin/bash
# MIT License
# Copyright (c) 2025 Lil5354
# Script to setup Oracle Cloud server for EcoCheck deployment

set -e

echo "=========================================="
echo "Oracle Cloud Server Setup for EcoCheck"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "❌ Please do not run as root. Run as regular user."
    exit 1
fi

# Update system
echo "📦 Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    ufw

# Install Docker
echo ""
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Add user to docker group
    sudo usermod -aG docker $USER

    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

# Start and enable Docker
echo ""
echo "🚀 Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker
echo ""
echo "🔍 Verifying Docker installation..."
docker --version
docker compose version

# Setup firewall
echo ""
echo "🔥 Configuring firewall..."
sudo ufw --force enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow 3000/tcp # Backend API

echo ""
echo "✅ Firewall configured"
sudo ufw status

# Clone repository
echo ""
echo "📥 Cloning EcoCheck repository..."
if [ ! -d "EcoCheck-OLP-2025" ]; then
    git clone https://github.com/Lil5354/EcoCheck-OLP-2025.git
    cd EcoCheck-OLP-2025
    git checkout TWeb
else
    echo "Repository already exists. Updating..."
    cd EcoCheck-OLP-2025
    git pull origin TWeb
fi

# Create .env file
echo ""
echo "📝 Creating .env file..."
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "✅ Created .env from .env.example"
        echo ""
        echo "⚠️  IMPORTANT: Please edit .env file with your configuration:"
        echo "   - DOCKER_REGISTRY=lilweyy5354"
        echo "   - DB_PASSWORD=your_secure_password"
        echo "   - VITE_API_URL=http://YOUR_PUBLIC_IP:3000"
        echo ""
        echo "Edit with: nano .env"
    else
        echo "⚠️  .env.example not found. Please create .env manually."
    fi
else
    echo "✅ .env file already exists"
fi

echo ""
echo "=========================================="
echo "✅ Server setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Edit .env file: nano .env"
echo "2. Update VITE_API_URL with your public IP"
echo "3. Set a strong DB_PASSWORD"
echo "4. Deploy: docker compose -f docker-compose.deploy.yml pull"
echo "5. Start: docker compose -f docker-compose.deploy.yml up -d"
echo ""
echo "⚠️  IMPORTANT: Make sure to:"
echo "   - Open ports 22, 80, 443, 3000 in Oracle Cloud Security List"
echo "   - Logout and login again to apply docker group changes"
echo ""


