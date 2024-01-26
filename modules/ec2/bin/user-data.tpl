#!/bin/bash


sudo dnf update -y
sudo dnf install -y docker jq amazon-ecr-credential-helper
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
newgrp docker
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

mkdir -p /home/ec2-user/.docker/
cat >/home/ec2-user/.docker/config.json <<EOL
{
	"credsStore": "ecr-login"
}
EOL

aws ecr get-login-password | docker login --username AWS --password-stdin ${DOCKER_REGISTRY_URL}

cat > /home/ec2-user/.env << EOL
DJANGO_SETTINGS_MODULE="${DJANGO_SETTINGS_MODULE}"
DJANGO_ENV="${DJANGO_ENV}"
EOL

cat >/home/ec2-user/docker-compose.yaml <<EOL
${compose_file}
EOL

cd /home/ec2-user/
docker-compose up -d
