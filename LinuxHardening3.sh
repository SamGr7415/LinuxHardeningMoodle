#!/bin/bash

# Message de la bannière légale en français et en anglais
BANNER="********************************************************************************
*                          ATTENTION - AVERTISSEMENT                            *
*                                                                              *
* Ce système est réservé aux utilisateurs autorisés seulement.                 *
* L'accès ou l'utilisation non autorisés est interdit et peut entraîner        *
* des mesures disciplinaires et/ou des sanctions civiles et pénales.           *
*                                                                              *
* Toutes les activités sur ce système sont surveillées et enregistrées.        *
*                                                                              *
* En accédant à ce système, vous consentez à une telle surveillance et         *
* enregistrement.                                                              *
********************************************************************************
*                          ATTENTION - WARNING                                 *
*                                                                              *
* This system is restricted to authorized users only. Unauthorized access      *
* or use is prohibited and may result in disciplinary action and/or civil      *
* and criminal penalties.                                                      *
*                                                                              *
* All activities on this system are monitored and recorded.                    *
*                                                                              *
* By accessing this system, you consent to such monitoring and recording.      *
********************************************************************************"

# Ajouter la bannière à /etc/issue
echo "$BANNER" | sudo tee /etc/issue

# Ajouter la bannière à /etc/issue.net
echo "$BANNER" | sudo tee /etc/issue.net

echo "Les bannières légales ont été ajoutées à /etc/issue et /etc/issue.net."
