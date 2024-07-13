#!/bin/bash

# Fonction pour afficher un message
function log {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Définir l'encodage à UTF-8
export LANG=C.UTF-8

log "Début de l'application des nouvelles recommandations de durcissement..."

# 1. Installation de libpam-tmpdir
log "Installation de libpam-tmpdir pour sécuriser les variables TMP et TMPDIR..."
apt-get install -y libpam-tmpdir

# 2. Installation de apt-listbugs
log "Installation de apt-listbugs pour détecter les bugs critiques avant l'installation des paquets..."
apt-get install -y apt-listbugs

# 3. Installation de needrestart
log "Installation de needrestart pour vérifier les services à redémarrer après les mises à jour..."
apt-get install -y needrestart

# 4. Installation de fail2ban
log "Installation de fail2ban pour bloquer automatiquement les tentatives d'authentification multiples..."
apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# 5. Vérification du service fail2ban
log "Vérification du service fail2ban..."
if systemctl is-active --quiet fail2ban; then
    log "Le service fail2ban fonctionne correctement."
else
    log "Le service fail2ban ne fonctionne pas. Tentative de démarrage manuel..."
    systemctl start fail2ban
    if systemctl is-active --quiet fail2ban; then
        log "Le service fail2ban a démarré avec succès."
    else
        log "Échec du démarrage du service fail2ban. Veuillez vérifier les logs pour plus de détails."
    fi
fi

# 6. Analyse de la sécurité des services
log "Analyse de la sécurité des services avec systemd-analyze security..."
for service in $(systemctl list-units --type service --state running --no-pager --no-legend | awk '{print $1}'); do
    log "Sécurité du service : $service"
    systemd-analyze security $service
done

# 7. Désactivation explicite des core dumps
log "Désactivation explicite des core dumps..."
echo "* hard core 0" >> /etc/security/limits.conf

log "Application des nouvelles recommandations de durcissement terminée."
