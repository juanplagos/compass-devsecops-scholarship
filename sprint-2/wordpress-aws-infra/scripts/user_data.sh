#!/bin/bash

# Atualiza pacotes e instala o Docker
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

# Monta o sistema de arquivos
yum install -y amazon-efs-utils
mkdir -p /mnt/efs
mount -t efs -o tls <efs_id>:/ /mnt/efs 
echo "<efs_id>:/ /mnt/efs efs _netdev,tls 0 0" >> /etc/fstab

# Instala o docker compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Cria o arquivo docker compose
cat << EOF > /home/ec2-user/docker-compose.yml
version: '3'
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: <endpoint_do_rds>.us-east-1.rds.amazonaws.com
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: <segredo_do_rds>
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - /mnt/efs/wp-content:/var/www/html/wp-content  
    restart: always
EOF

# Inicializa o contêiner do WordPress
docker-compose -f /home/ec2-user/docker-compose.yml up -d