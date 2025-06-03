#!/bin/bash
set -euo pipefail

# Message de la bannière légale en français et en anglais
read -r -d '' BANNER <<'BANNER'
*******************************************************************************
*                          ATTENTION - AVERTISSEMENT                          *
*                                                                             *
* Ce système est réservé aux utilisateurs autorisés seulement.                *
* L'accès ou l'utilisation non autorisés est interdit et peut entraîner       *
* des mesures disciplinaires et/ou des sanctions civiles et pénales.          *
*                                                                             *
* Toutes les activités sur ce système sont surveillées et enregistrées.       *
*                                                                             *
* En accédant à ce système, vous consentez à une telle surveillance et        *
* enregistrement.                                                             *
*******************************************************************************
*                          ATTENTION - WARNING                                *
*                                                                             *
* This system is restricted to authorized users only. Unauthorized access     *
* or use is prohibited and may result in disciplinary action and/or civil     *
* and criminal penalties.                                                     *
*                                                                             *
* All activities on this system are monitored and recorded.                   *
*                                                                             *
* By accessing this system, you consent to such monitoring and recording.     *
*******************************************************************************
BANNER

# Ajouter la bannière aux fichiers de connexion
if (( EUID != 0 )); then
    echo "Ce script doit être exécuté en tant que root" >&2
    exit 1
fi

echo "$BANNER" > /etc/issue
echo "$BANNER" > /etc/issue.net

echo "Les bannières légales ont été ajoutées à /etc/issue et /etc/issue.net."
