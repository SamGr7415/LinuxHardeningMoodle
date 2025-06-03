#!/bin/bash
set -euo pipefail

# Affiche un message horodaté
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

if (( EUID != 0 )); then
    echo "Ce script doit être exécuté en tant que root" >&2
    exit 1
fi

log "Renforcement de la configuration de CUPS..."

# 1. Restreindre l'accès au fichier de configuration
log "Restreindre l'accès au fichier de configuration de CUPS..."
chmod 644 /etc/cups/cupsd.conf
chown root:lp /etc/cups/cupsd.conf

# 2. Restreindre l'accès à l'interface web de CUPS
log "Modification du fichier de configuration de CUPS pour restreindre l'accès à l'interface web..."

# Sauvegarder la configuration actuelle
cp /etc/cups/cupsd.conf /etc/cups/cupsd.conf.bak

# Modifier le fichier cupsd.conf pour restreindre l'accès à l'interface web si cela n'a pas déjà été fait
if ! grep -q "<Location />" /etc/cups/cupsd.conf; then
cat <<'EOF' >> /etc/cups/cupsd.conf

# Restreindre l'accès à l'interface web de CUPS
<Location />
  Order allow,deny
  Allow from 127.0.0.1
  Allow from ::1
</Location>

<Location /admin>
  Order allow,deny
  Allow from 127.0.0.1
  Allow from ::1
</Location>

<Location /admin/conf>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
  Allow from 127.0.0.1
  Allow from ::1
</Location>
EOF
fi

# 3. Redémarrer le service CUPS pour appliquer les modifications
log "Redémarrage du service CUPS..."
systemctl restart cups

log "Renforcement de la configuration de CUPS terminé."
