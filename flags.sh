#!/bin/bash
# =============================================================================
# flags.sh — Bibliothèque de génération de flags HMAC-déterministe.
# Sourcé par provision.sh et seed.sh côté DC, et par web/entrypoint.sh côté web.
# =============================================================================
# flag_for "<stage>" "<theme>" -> écrit sur stdout la valeur FLAG{theme_hash12}
#
# La valeur est déterministe pour un même couple (CTF_SECRET, stage), donc
# reproductible entre `make reset` tant que le secret ne change pas.
# Le theme reste lisible pour conserver l'intention pédagogique du flag.
# =============================================================================

: "${CTF_SECRET:?[!] CTF_SECRET requis (cf. .env / .env.example)}"

flag_for() {
    local stage="$1"
    local theme="$2"
    local h
    h=$(printf '%s:%s' "${CTF_SECRET}" "${stage}" | sha256sum | cut -c1-12)
    printf 'FLAG{%s_%s}' "${theme}" "${h}"
}
