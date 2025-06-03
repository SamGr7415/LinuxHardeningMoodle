#!/bin/bash
set -euo pipefail

# Affiche un message horodaté
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

export LANG=C.UTF-8

# Vérifie que le script est exécuté en tant que root
if (( EUID != 0 )); then
    echo "Ce script doit être exécuté en tant que root" >&2
    exit 1
fi

log "Début de l'application des nouvelles recommandations de durcissement..."

# Installation des outils recommandés
log "Installation des dépendances de durcissement..."
apt-get install -y libpam-tmpdir apt-listbugs needrestart fail2ban

# 4. Activation de fail2ban
log "Installation de fail2ban pour bloquer automatiquement les tentatives d'authentification multiples..."
systemctl enable fail2ban
systemctl start fail2ban

# 5. Vérification du service fail2ban
log "Vérification du service fail2ban..."
if systemctl is-active --quiet fail2ban; then
    log "Le service fail2ban fonctionne correctement."
else
    log "Le service fail2ban ne fonctionne pas. Tentative de démarrage manuel..."
    systemctl start fail2ban || log "Échec du démarrage du service fail2ban."
fi

# 6. Analyse de la sécurité des services
log "Analyse de la sécurité des services avec systemd-analyze security..."
systemctl list-units --type service --state running --no-pager --no-legend | awk '{print $1}' | while read -r service; do
    log "Sécurité du service : $service"
    systemd-analyze security "$service"
done

# 7. Désactivation explicite des core dumps
log "Désactivation explicite des core dumps..."
echo "* hard core 0" >> /etc/security/limits.conf

log "Application des nouvelles recommandations de durcissement terminée."
