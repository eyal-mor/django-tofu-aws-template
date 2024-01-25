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

aws ecr get-login-password | docker login --username AWS --password-stdin XXXX.dkr.ecr.us-east-1.amazonaws.com/XXXX

RDS_SECRETS=$(aws secretsmanager get-secret-value --secret-id "${SECRETS_MANAGER_RDS_PATH}" | jq '.SecretString' | jq -r)
RDS_USER=$(echo $RDS_SECRETS | jq -r '.username')
# The python script urlencodes the password, this is due to some edge cases in python where specific characters can break parsing libraries (e.g. celery)
RDS_PASSWORD=$(echo $RDS_SECRETS | jq -r '.password' | python3 -c "import sys; from urllib import parse; sys.stdout.write(parse.quote_plus(sys.stdin.read().rstrip()))")
DJANGO_SECRET_KEY=$(aws secretsmanager get-secret-value --secret-id "${SECRETS_MANAGER_DJANGO_SECRET_PATH}" | jq '.SecretString' | jq -r | jq -r '.SECRET_KEY')

cat > /home/ec2-user/.env << EOL
DJANGO_SETTINGS_MODULE="${DJANGO_SETTINGS_MODULE}"
DJANGO_ENV="${DJANGO_ENV}"
SECRET_KEY="$${DJANGO_SECRET_KEY}"
DATABASE_URL="postgres://$${RDS_USER}:$${RDS_PASSWORD}@${RDS_URL}:${RDS_PORT}/${DATABASE_NAME}"
EOL

cat >/home/ec2-user/docker-compose.yaml <<EOL
${compose_file}
EOL

cd /home/ec2-user/
docker-compose up -d
