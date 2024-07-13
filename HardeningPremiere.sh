#!/bin/bash

# Fonction pour afficher un message
function log {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log "Début du durcissement du serveur Moodle..."

# 1. Mettre à jour le système
log "Mise à jour du système..."
apt-get update && apt-get upgrade -y

# 2. Désactiver les services inutiles
log "Désactivation des services non nécessaires..."
systemctl disable avahi-daemon
systemctl disable cups
systemctl disable bluetooth
systemctl disable rpcbind

# 3. Configuration de l'UMASK
log "Configuration de l'UMASK..."
echo "UMASK 027" >> /etc/login.defs
sed -i 's/UMASK.*022/UMASK 027/' /etc/profile

# 4. Configuration du chargeur de démarrage
log "Configuration du chargeur de démarrage..."
sed -i 's/^#GRUB_PASSWORD/GRUB_PASSWORD/' /etc/default/grub
echo 'set superusers="root"' >> /etc/grub.d/40_custom
echo 'password_pbkdf2 root GRUB_PASSWORD_HASH' >> /etc/grub.d/40_custom
update-grub

# 5. Cloisonnement des services réseau
log "Cloisonnement des services réseau..."
usermod -aG www-data www-data
mkdir -p /var/www/moodle_data
chown -R www-data:www-data /var/www/moodle_data
chmod -R 750 /var/www/moodle_data

# 6. Configuration de AppArmor
log "Configuration de AppArmor..."
apt-get install -y apparmor apparmor-utils
systemctl enable apparmor
systemctl start apparmor

log "Activation des profils AppArmor..."
aa-enforce /etc/apparmor.d/*

# 7. Utiliser des dépôts de paquets de confiance
log "Configuration des dépôts de paquets de confiance..."
cat <<EOF > /etc/apt/sources.list.d/secure-repos.list
deb http://security.debian.org/debian-security bullseye-security main
deb http://deb.debian.org/debian bullseye-updates main
EOF
apt-get update

# 8. Mise en place d'un système de journalisation
log "Configuration du système de journalisation..."
apt-get install -y auditd
systemctl enable auditd
auditctl -e 1
cat <<EOF > /etc/audit/rules.d/audit.rules
-w /etc/shadow -p wa -k passwd_changes
-w /var/www/moodle -p wa -k moodle_changes
-w /etc/passwd -p wa -k passwd_changes
-w /etc/group -p wa -k group_changes
-w /etc/gshadow -p wa -k gshadow_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/ssh/sshd_config -p wa -k sshd_config_changes
EOF

# 9. Surveillance de l'intégrité des fichiers
log "Installation et configuration de AIDE..."
apt-get install -y aide
aideinit
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
echo "0 0 * * * /usr/bin/aide --check" >> /etc/crontab

# 10. Sécurisation des accès SSH
log "Sécurisation des accès SSH..."
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sed -i 's/^#ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config
sed -i 's/^#LogLevel.*/LogLevel VERBOSE/' /etc/ssh/sshd_config
systemctl reload sshd

# 11. Mise en place du pare-feu
log "Configuration du pare-feu avec UFW..."
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 1514/tcp  # Port par défaut de Wazuh
ufw allow 10050/tcp # Port par défaut de Zabbix
ufw enable

# 12. Paramètres de sécurité du noyau
log "Configuration des paramètres de sécurité du noyau..."
cat <<EOF > /etc/sysctl.d/99-sysctl.conf
# Sécurité réseau
net.ipv4.ip_forward=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# Renforcement de la sécurité
kernel.randomize_va_space=2
kernel.dmesg_restrict=1
kernel.kptr_restrict=2
kernel.sysrq=0
EOF
sysctl --system

# 13. Sauvegardes régulières
log "Configuration des sauvegardes régulières..."
apt-get install -y rsync
mkdir -p /var/backups/moodle
crontab -l | { cat; echo "0 2 * * * rsync -a /var/www/moodle /var/backups/moodle"; } | crontab -

# 14. Désactivation du chargement de nouveaux modules noyau
log "Désactivation du chargement de nouveaux modules noyau..."
echo "kernel.modules_disabled=1" >> /etc/sysctl.conf
sysctl -p

# 15. Configuration de sudo
log "Configuration sécurisée de sudo..."
chmod 750 /etc/sudoers
chmod 750 /etc/sudoers.d
chown -R root:root /etc/sudoers
chown -R root:root /etc/sudoers.d

# 16. Politique de mot de passe stricte
log "Application de politiques de mot de passe strictes..."
apt-get install -y libpam-pwquality
cat <<EOF > /etc/pam.d/common-password
password requisite pam_pwquality.so retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1
password [success=1 default=ignore] pam_unix.so obscure use_authtok try_first_pass sha512
EOF

# 17. Application des correctifs de sécurité
log "Application des correctifs de sécurité..."
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# 18. Nettoyage final
log "Nettoyage du système..."
apt-get autoremove -y
apt-get clean

log "Durcissement du serveur terminé."
