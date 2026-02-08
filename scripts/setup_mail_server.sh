#!/bin/bash
# Multi-Tenant Business Email Server Setup Script
# Target OS: Ubuntu 22.04 / 24.04

set -e

# Configuration
DOMAIN="mx.webhizzy.in"
DB_NAME="mailserver"
DB_USER="mailuser"
DB_PASS="secure_password"

echo "Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get upgrade -y

echo "Installing Postfix, Dovecot, MariaDB, and Rspamd..."
apt-get install -y postfix postfix-mysql dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql mariadb-server rsync curl

# Install Rspamd
mkdir -p /etc/apt/keyrings
curl -L https://rspamd.com/apt-stable/gpg.key | gpg --dearmor -o /etc/apt/keyrings/rspamd.gpg
echo "deb [signed-by=/etc/apt/keyrings/rspamd.gpg] http://rspamd.com/apt-stable/ $(lsb_release -c -s) main" > /etc/apt/sources.list.d/rspamd.list
apt-get update && apt-get install -y rspamd

# Database Setup
echo "Configuring Database..."
mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "FLUSH PRIVILEGES;"

# Apply Schema (assumes schema.sql is in the same dir)
mysql $DB_NAME < /root/mail_server_schema.sql

# User for mailboxes
groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /var/mail/vhosts -m

# Copy Configs
echo "Applying Configurations..."
cp /root/postfix_main.cf /etc/postfix/main.cf
cp /root/mysql-virtual-mailbox-domains.cf /etc/postfix/
cp /root/mysql-virtual-mailbox-maps.cf /etc/postfix/
cp /root/mysql-virtual-alias-maps.cf /etc/postfix/
cp /root/dovecot-sql.conf.ext /etc/dovecot/

# Dovecot Main Overrides
cat <<EOF > /etc/dovecot/local.conf
mail_location = maildir:/var/mail/vhosts/%d/%n
auth_mechanisms = plain login
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
  }
}
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
userdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
EOF

# Restart Services
systemctl restart mariadb postfix dovecot rspamd

echo "Setup Complete! Primary MX: $DOMAIN"
echo "Don't forget to run Certbot for SSL certificates."
