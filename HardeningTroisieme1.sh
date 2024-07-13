#!/bin/bash

# Fonction pour afficher un message
function log {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log "Début de la configuration des shells selon les recommandations de l'ANSSI..."

# 1. Configurer le délai d'expiration des sessions
log "Configuration du délai d'expiration des sessions..."

# Ajout de la variable TMOUT pour les sessions bash
echo "TMOUT=900" | sudo tee -a /etc/profile.d/timeout.sh
echo "export TMOUT" | sudo tee -a /etc/profile.d/timeout.sh

# Appliquer la configuration immédiatement pour les sessions en cours
source /etc/profile.d/timeout.sh

log "Délai d'expiration des sessions configuré à 15 minutes (900 secondes)."

# 2. Configurer les valeurs par défaut de l'umask
log "Configuration des valeurs par défaut de l'umask..."

# Configuration de l'umask dans /etc/profile
if grep -q "umask" /etc/profile; then
    sudo sed -i 's/^umask .*/umask 027/' /etc/profile
else
    echo "umask 027" | sudo tee -a /etc/profile
fi

# Configuration de l'umask dans /etc/bash.bashrc
if grep -q "umask" /etc/bash.bashrc; then
    sudo sed -i 's/^umask .*/umask 027/' /etc/bash.bashrc
else
    echo "umask 027" | sudo tee -a /etc/bash.bashrc
fi

# Appliquer la configuration immédiatement pour les sessions en cours
source /etc/profile
source /etc/bash.bashrc

log "Valeur par défaut de l'umask configurée à 027."

log "Configuration des shells selon les recommandations de l'ANSSI terminée."
