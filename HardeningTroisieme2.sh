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

log "Début de la restriction d'accès aux compilateurs uniquement à root..."

# Liste des compilateurs courants
compilers=(
    "/usr/bin/gcc"
    "/usr/bin/g++"
    "/usr/bin/clang"
    "/usr/bin/make"
)

# Restreindre l'accès aux compilateurs uniquement à root
for compiler in "${compilers[@]}"; do
    if [ -f "$compiler" ]; then
        log "Restriction d'accès à $compiler"
        chmod 700 "$compiler"
    else
        log "Compilateur $compiler non trouvé"
    fi
done

log "Restriction d'accès aux compilateurs terminée."
