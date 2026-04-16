#!/bin/bash
# scripts/ldap/ldap_setup.sh
# Installs and configures LDAP Account Manager (LAM)

set -e

echo "→ Installing LAM and dependencies..."
apt-get install -y \
    ldap-account-manager \
    php \
    php-ldap \
    php-fpm \
    nginx

echo "→ Stopping Apache if running..."
systemctl stop apache2 2>/dev/null || true
systemctl disable apache2 2>/dev/null || true

# Detect installed PHP version
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null \
          || ls /etc/php/ 2>/dev/null | sort -V | tail -1 \
          || echo "8.3")
PHP_FPM_SOCK="/var/run/php/php${PHP_VER}-fpm.sock"
echo "→ PHP ${PHP_VER} detected (socket: ${PHP_FPM_SOCK})"

echo "→ Restoring main nginx.conf..."
cat > /etc/nginx/nginx.conf << 'MAIN_CONF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    gzip on;
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
MAIN_CONF

echo "→ Configuring Nginx for LAM..."
cat > /etc/nginx/sites-available/lam << 'NGINX_CONF'
server {
    listen 80;
    server_name _;

    root /usr/share/ldap-account-manager;
    index index.html;

    location = / {
        return 301 /templates/login.php;
    }

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass unix:__PHP_FPM_SOCK__;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
NGINX_CONF

# Replace placeholder with actual PHP-FPM socket
sed -i "s|__PHP_FPM_SOCK__|${PHP_FPM_SOCK}|g" /etc/nginx/sites-available/lam

echo "→ Enabling LAM site in Nginx..."
ln -sf /etc/nginx/sites-available/lam /etc/nginx/sites-enabled/lam
rm -f /etc/nginx/sites-enabled/default

echo "→ Starting PHP-FPM and Nginx..."
systemctl enable "php${PHP_VER}-fpm"
systemctl start  "php${PHP_VER}-fpm"
systemctl enable nginx
systemctl restart nginx

echo "→ Configuring LAM profile for TechNova..."
LAM_CONF_DIR="/var/lib/ldap-account-manager/config"
mkdir -p "$LAM_CONF_DIR"

cat > "${LAM_CONF_DIR}/lam.conf" << 'LAM_PROFILE'
# LAM profile — TechNova
ServerURL: ldap://127.0.0.1:389
Admins: uid=sysadmin,ou=users,dc=technova,dc=local
Passwd: Sysadmin2026!
defaultLanguage: en_GB.utf8
usersuffix: ou=users,dc=technova,dc=local
groupsuffix: ou=groups,dc=technova,dc=local
loginMethod: search
loginSearchSuffix: dc=technova,dc=local
loginSearchFilter: (&(uid=%USER%)(uid=sysadmin))
loginSearchDN: cn=admin,dc=technova,dc=local
loginSearchPassword: manager
listAttributes: #uid;#givenName;#sn;#uidNumber;#gidNumber
types: suffix_user: ou=users,dc=technova,dc=local
types: attr_user: #uid;#givenName;#sn;#uidNumber;#gidNumber
types: modules_user: inetOrgPerson,posixAccount,shadowAccount,sambaSamAccount
types: suffix_group: ou=groups,dc=technova,dc=local
types: attr_group: #cn;#gidNumber
types: modules_group: posixGroup
moduleSettings: posixAccount_user_minUID: 3000
moduleSettings: posixAccount_user_maxUID: 9999
moduleSettings: posixAccount_user_uidGeneratorUsers: free
moduleSettings: posixAccount_user_uidCheckSuffixUser: 5000
moduleSettings: posixAccount_pwdHash: SSHA
moduleSettings: posixAccount_shells: /bin/bash+::+/sbin/nologin
moduleSettings: posixAccount_group_minGID: 5000
moduleSettings: posixAccount_group_maxGID: 5999
tools: tool_hide_toolLamdaemon: false
LAM_PROFILE

echo "→ Setting correct permissions..."
chown -R www-data:www-data /var/lib/ldap-account-manager/
chmod -R 750 /var/lib/ldap-account-manager/

echo "✓ LAM successfully installed"
echo "  Access at: http://192.168.10.10"
echo "  LAM login: sysadmin / Sysadmin2026!"
echo "  LAM config password: Sysadmin2026!"