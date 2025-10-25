# Security's Sistem Project

## Operational Sistem (Tests Virtual Machine)

- **OS:** Ubuntu 24.04.3 LTS (Noble Numbat)
- **Kernel:** Linux 6.8.0-86-generic
- **Architecture:** x86-64
- **Virtualization:** Oracle VirtualBox (KVM)
- **CPU:** Intel Core i7-1260P (4 cores, 12th Gen)
- **Memory:** 2GB RAM, 2GB Swap
- **Disk:** 12GB root partition (65% used)
- **Network:** IP 172.20.10.14/28 (enp0s3)

## Setup Server

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install openssh-server openssh-client -y
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh
```


## Setup Client

```bash
ssh-keygen -t ed25519
ssh-copy-id <user>@<host>
ssh <user>@<host>
```

## Cloning Repository

```bash
mkdir -p /app && cd /app
git clone https://github.com/KauanCalheiro/ss-wordpress.git
```

## Multiplexing SSH and HTTPS on Port 443

### Alter SSH in port 2022

```bash
sudo tee -a /etc/ssh/sshd_config << EOF
Port 22
Port 2022
EOF

sudo reboot
```

### Install and configure sshttp

```bash
cd /app/ss-wordpress/sshttp/src

sudo apt install build-essential libcap-dev git -y

sudo make

sudo /app/ss-wordpress/sshttp/iptables/nf-setup

sudo mkdir -p /var/empty/sshttp
sudo chmod 755 /var/empty/sshttp

sudo /app/ss-wordpress/sshttp/src/sshttpd -S 2022 -L 443 -H 4433 -R /var/empty/sshttp
```

## Docker installation

```bash
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
sudo systemctl status docker
```

## WordPress Setup

### Disable Apache2 to free port 80

```bash
sudo systemctl stop apache2
sudo systemctl disable apache2
```

### WordPress Installation

```bash
cd /app/ss-wordpress

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
```

## SSH Configuration

```bash
sudo tee -a /etc/ssh/sshd_config << EOF
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
EOF

sudo systemctl restart sshd
sudo systemctl status sshd
```

## Fail2ban Configuration

```bash
sudo apt install fail2ban -y

sudo tee /etc/fail2ban/filter.d/sshd-aggressive.conf << EOF
[Definition]
failregex = ^.* sshd\[.*\]: Failed .* from <HOST>
            ^.* sshd\[.*\]: Invalid user .* from <HOST>
            ^.* sshd\[.*\]: Connection closed by authenticating user .* <HOST> port .* \[preauth\]
            ^.* sshd\[.*\]: Disconnected from authenticating user .* <HOST> port .* \[preauth\]
ignoreregex =
EOF

sudo tee /etc/fail2ban/jail.local << EOF
# SSH direto na porta 22 (fallback/backup)
[sshd-direct]
enabled = true
port = 22
filter = sshd-aggressive
logpath = /var/log/auth.log
maxretry = 3
bantime = 600
findtime = 600

# SSH via SSLH na porta 443 (principal)
[sshd-sslh]
enabled = true
port = 443
filter = sshd-aggressive
logpath = /var/log/auth.log
maxretry = 3
bantime = 600
findtime = 600
EOF

sudo systemctl restart fail2ban
sudo systemctl status fail2ban
```

### Check status of fail2ban

```bash
sudo fail2ban-client status sshd-direct
sudo fail2ban-client status sshd-sslh

sudo fail2ban-client status
```