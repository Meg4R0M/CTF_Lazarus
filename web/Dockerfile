FROM php:8.2-apache

# =============================================================================
# Humanix CTF — Conteneur web (intranet vulnérable)
# Sert l'intranet PHP + le fichier de backup "oublié" qui leak le credential.
# Les valeurs de flags ne sont JAMAIS dans l'image : elles sont rendues au
# démarrage par l'entrypoint depuis CTF_SECRET.
#
# Build context : racine du repo (compose le passe via context: .)
# =============================================================================

# Sources statiques + template (avec placeholder __FLAG_WEB__)
COPY web/src/ /srv/www-src/

# Bibliothèque de génération de flags partagée avec le DC
COPY flags.sh /usr/local/lib/flags.sh

# Entrypoint qui rend les templates dans /var/www/html
COPY web/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/lib/flags.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
