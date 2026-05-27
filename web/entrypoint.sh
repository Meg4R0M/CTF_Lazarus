#!/bin/bash
set -euo pipefail

# =============================================================================
# entrypoint.sh — Rend les templates statiques en injectant les flags dérivés
# de CTF_SECRET, puis exécute la commande Apache passée en argument.
# =============================================================================

# shellcheck source=/dev/null
. /usr/local/lib/flags.sh

FLAG_WEB=$(flag_for "web_recon" "l34k_conf1rm3d")

# Copie le contenu source vers le DocumentRoot Apache
cp -r /srv/www-src/. /var/www/html/

# Substitution du placeholder dans le fichier "fuité"
sed -i "s|__FLAG_WEB__|${FLAG_WEB}|g" /var/www/html/backup/config.bak.txt

chown -R www-data:www-data /var/www/html

exec "$@"
