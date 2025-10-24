#!/bin/bash

sudo apt update
sudo apt install sslh -y

sudo tee /etc/default/sslh << EOF
DAEMON=/usr/sbin/sslh
RUN=yes
DAEMON_OPTS="--user sslh --listen 0.0.0.0:443 --ssh 127.0.0.1:22 --tls 127.0.0.1:4433 --pidfile /var/run/sslh/sslh.pid"
EOF

sudo tee /etc/tmpfiles.d/sslh.conf > /dev/null << EOF
d /var/run/sslh 0755 sslh sslh -
f /var/run/sslh/sslh.pid 0644 sslh sslh -
EOF

sudo systemd-tmpfiles --create /etc/tmpfiles.d/sslh.conf

sudo systemctl enable sslh
sudo systemctl start sslh
sudo systemctl status sslh

sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo systemctl enable docker
sudo systemctl start docker

mkdir -p /app && cd /app
git clone https://github.com/KauanCalheiro/ss-wordpress.git
cd ss-wordpress

cat > .env << EOF
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=secure_password_123
MYSQL_ROOT_PASSWORD=root_secure_password_456
WORDPRESS_DB_HOST=db:3306
WORDPRESS_DB_NAME=wordpress_db
WORDPRESS_DB_USER=wordpress_user
WORDPRESS_DB_PASSWORD=secure_password_123
INTERNAL_NETWORK=wordpress_internal_network
EOF

bash generate-ssl.sh

sudo docker compose up -d
