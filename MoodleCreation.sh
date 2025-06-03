#!/bin/bash
set -e

# Petit utilitaire pour journaliser les actions avec un horodatage
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $*"
}

# Vérifier que le script est exécuté en tant que root
if [ "$(id -u)" -ne 0 ]; then
  echo "Ce script doit être lancé avec les privilèges administrateur." >&2
  exit 1
fi

# Paramètres personnalisables
DOMAIN="academicefrei.site"
ADMIN_EMAIL="admin@${DOMAIN}"

# Fonction pour générer un mot de passe aléatoire
generate_password() {
  openssl rand -base64 20 | tr -dc A-Za-z0-9 | head -c 20
}

log "Génération des mots de passe"
# Générer des mots de passe aléatoires
MARIADB_ROOT_PASSWORD=$(generate_password)
MOODLE_DB_PASSWORD=$(generate_password)

log "Mise à jour du système"
# Mettre à jour la liste des paquets et les paquets
export DEBIAN_FRONTEND=noninteractive
apt-get update
log "Installation des paquets"
apt-get -y upgrade

log "Activation de MariaDB"
# Installer les paquets nécessaires
apt-get install -y apache2 mariadb-server php libapache2-mod-php php-mysql php-xml php-curl php-zip php-gd php-intl php-mbstring git

# Démarrer et activer le service MariaDB
systemctl enable --now mariadb

# Sécuriser l'installation de MariaDB et définir le mot de passe root
log "Configuration de MariaDB"
mysql --user=root <<_EOF_
  ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
  FLUSH PRIVILEGES;
_EOF_

log "Téléchargement de Moodle"
# Définir la version de Moodle et les répertoires
MOODLE_VERSION=MOODLE_404_STABLE
MOODLE_DIR=/var/www/html/moodle
MOODLEDATA_DIR=/var/moodledata

# Télécharger MOODLE_404_STABLE
if [ ! -d "/var/www/html" ]; then
  mkdir -p /var/www/html
fi
cd /var/www/html
if [ ! -d "$MOODLE_DIR" ]; then
  git clone git://git.moodle.org/moodle.git moodle
  cd moodle
  git checkout -b $MOODLE_VERSION origin/$MOODLE_VERSION
else
  echo "Le répertoire Moodle existe déjà. Clonage ignoré."
fi

# Créer le répertoire de données de Moodle
if [ ! -d "$MOODLEDATA_DIR" ]; then
  mkdir /var/moodledata
  chown -R www-data:www-data /var/moodledata
else
  echo "Le répertoire de données de Moodle existe déjà."
fi

# Définir les permissions correctes
chown -R www-data:www-data $MOODLE_DIR
chmod -R 755 $MOODLE_DIR

# Créer la base de données et l'utilisateur pour Moodle
mysql --user=root --password="$MARIADB_ROOT_PASSWORD" <<_EOF_
  CREATE DATABASE IF NOT EXISTS moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE USER IF NOT EXISTS 'moodleuser'@'localhost' IDENTIFIED BY '${MOODLE_DB_PASSWORD}';
  GRANT ALL PRIVILEGES ON moodle.* TO 'moodleuser'@'localhost';
  FLUSH PRIVILEGES;
_EOF_

# Enregistrer les mots de passe dans un fichier sécurisé
PASSWORD_FILE=/root/mariadb_passwords.txt
echo "Mot de passe root MariaDB: ${MARIADB_ROOT_PASSWORD}" > $PASSWORD_FILE
echo "Mot de passe de l'utilisateur de la base de données Moodle 'moodleuser': ${MOODLE_DB_PASSWORD}" >> $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Créer un hôte virtuel pour Moodle
if [ ! -f "/etc/apache2/sites-available/moodle.conf" ]; then
log "Configuration de l'hote virtuel"
  cat <<EOF > /etc/apache2/sites-available/moodle.conf
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot /var/www/html/moodle
    <Directory /var/www/html/moodle>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
else
  echo "La configuration de l'hôte virtuel Moodle existe déjà."
fi

# Activer le site Moodle et le module rewrite
a2ensite moodle.conf
log "Obtention du certificat"
a2enmod rewrite

# Redémarrer Apache pour appliquer les changements
systemctl restart apache2

# Installer Certbot en utilisant APT
apt-get install -y certbot python3-certbot-apache

# Obtenir le certificat SSL pour le domaine
certbot --apache -d "$DOMAIN" --non-interactive --agree-tos -m "$ADMIN_EMAIL"

# Configurer le renouvellement automatique
echo "0 0,12 * * * root certbot renew --quiet" > /etc/cron.d/certbot-renew

# Redémarrer Apache pour appliquer les changements
systemctl restart apache2

log "Fin de l'installation"
# Afficher les mots de passe générés
echo "Script d'installation terminé."
echo "Mot de passe root MariaDB: ${MARIADB_ROOT_PASSWORD}"
echo "Mot de passe de l'utilisateur de la base de données Moodle 'moodleuser': ${MOODLE_DB_PASSWORD}"
echo "Les mots de passe ont été sauvegardés dans ${PASSWORD_FILE}."
echo "Veuillez ouvrir votre navigateur et naviguer vers http://$DOMAIN pour compléter l'installation via l'interface web."

# Vérifier et afficher les utilisateurs MariaDB
mysql --user=root --password="$MARIADB_ROOT_PASSWORD" <<_EOF_
  SELECT User, Host FROM mysql.user;
  SHOW GRANTS FOR 'moodleuser'@'localhost';
_EOF_
