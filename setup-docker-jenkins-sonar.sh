#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root!" >&2
    exit 1
fi

# Update and upgrade system packages
echo "Updating system packages..."
apt-get update -y && apt-get upgrade -y

# Install dependencies
echo "Installing necessary dependencies..."
apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2 unzip

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
else
    echo "Docker is already installed."
fi

# Add current user to the Docker group
echo "Adding user to Docker group..."
usermod -aG docker "$USER"

# Install Docker Compose
echo "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi

# Install Jenkins
echo "Installing Jenkins..."
if ! command -v java &> /dev/null; then
    apt-get install -y openjdk-11-jdk
fi

if ! systemctl list-unit-files | grep -q jenkins.service; then
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | tee /etc/apt/sources.list.d/jenkins.list
    apt-get update -y
    apt-get install -y jenkins
    systemctl start jenkins
    systemctl enable jenkins
else
    echo "Jenkins is already installed."
fi

# Add current user to the Jenkins group
echo "Adding user to Jenkins group..."
usermod -aG jenkins "$USER"

# Install SonarQube
echo "Setting up SonarQube server with Docker..."
docker run -d --name sonarqube -p 9000:9000 sonarqube:latest

# Install Trivy
echo "Installing Trivy..."
if ! command -v trivy &> /dev/null; then
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
else
    echo "Trivy is already installed."
fi

# Final Output
echo "Setup Complete!"
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker-compose --version)"
echo "Jenkins is running on http://localhost:8080"
echo "SonarQube is running on http://localhost:9000"
echo "Trivy version: $(trivy --version)"
echo "Re-login or restart your session to apply group changes."
