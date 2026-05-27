#!/bin/bash
set -euo pipefail

# =============================================================================
# provision.sh — Provisionne le domaine HUMANIX.LAB au premier démarrage,
# puis lance Samba en avant-plan. Idempotent : au reboot du conteneur,
# si le domaine existe déjà, on ne reprovisionne pas.
# =============================================================================

REALM="HUMANIX.LAB"
DOMAIN="HUMANIX"
DC_HOSTNAME="dc01"
ADMIN_PASS="Humanix-CTF-2026!"          # mot de passe Administrator (volontairement "fort" mais connu du formateur)
PROVISION_MARKER="/var/lib/samba/.provisioned"

# Bug Debian 12 (surtout arm64) : samba-tool ne trouve pas ses modules LDB
# (samba_secrets, samba_dsdb, etc.). Les modules vivent dans plusieurs dossiers
# selon le package qui les fournit (samba-libs, samba-dsdb-modules), donc on
# combine tous les chemins potentiels dans LDB_MODULES_PATH (séparateur ':').
PATHS=""
for d in \
    /usr/lib/*-linux-gnu/samba/ldb \
    /usr/lib/*-linux-gnu/ldb/modules/ldb \
    /usr/lib/samba/ldb \
    /usr/lib/ldb/modules/ldb ; do
    for resolved in $d; do
        [ -d "$resolved" ] && PATHS="${PATHS}:${resolved}"
    done
done
export LDB_MODULES_PATH="${PATHS#:}"
echo "[*] LDB_MODULES_PATH=${LDB_MODULES_PATH}"

# Diagnostic : si samba_secrets n'est nulle part, on le dit clairement.
SECRETS_SO=$(find /usr -name 'samba_secrets*.so' 2>/dev/null | head -1 || true)
if [ -z "$SECRETS_SO" ]; then
    echo "[!] samba_secrets.so introuvable sur le système. Packages manquants ?"
    echo "[!] Recherche de tous les modules LDB de samba :"
    find /usr -name '*.so' \( -path '*samba*' -o -path '*ldb*' \) 2>/dev/null | head -30
else
    echo "[*] samba_secrets trouvé : $SECRETS_SO"
fi

# Bibliothèque de génération de flags (sourcée pour exposer flag_for)
# shellcheck source=/dev/null
. /flags.sh

echo "[*] Hostname conteneur : $(hostname)"

if [ ! -f "$PROVISION_MARKER" ]; then
    echo "[*] Premier démarrage : provisioning du domaine ${REALM}..."

    # On nettoie toute conf résiduelle
    rm -f /etc/samba/smb.conf

    samba-tool domain provision \
        --use-rfc2307 \
        --realm="${REALM}" \
        --domain="${DOMAIN}" \
        --server-role=dc \
        --dns-backend=SAMBA_INTERNAL \
        --adminpass="${ADMIN_PASS}" \
        --host-name="${DC_HOSTNAME}"

    # Kerberos : on copie la krb5.conf générée par Samba
    cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

    # On désactive l'expiration du mot de passe Administrator (sinon le lab casse après X jours)
    samba-tool user setexpiry Administrator --noexpiry

    # -----------------------------------------------------------------------
    # Politique de mot de passe : on relâche TOUT.
    # Le scénario CTF nécessite des mots de passe faibles et cassables (`backup123`,
    # `Summer2024`). La policy AD par défaut (complexité + 7 chars + histo) les
    # refuserait silencieusement. On désactive donc complexité, historique, et
    # on tombe la longueur min à 1.
    # -----------------------------------------------------------------------
    echo "[*] Relâchement de la politique de mot de passe (lab CTF)..."
    samba-tool domain passwordsettings set --complexity=off       >/dev/null
    samba-tool domain passwordsettings set --history-length=0     >/dev/null
    samba-tool domain passwordsettings set --min-pwd-length=1     >/dev/null
    samba-tool domain passwordsettings set --min-pwd-age=0        >/dev/null
    samba-tool domain passwordsettings set --max-pwd-age=0        >/dev/null

    # Seed des utilisateurs / SPN / ACL vulnérables (utilise flag_for en interne)
    /seed.sh

    # -----------------------------------------------------------------------
    # Génération des fichiers de flags exposés via shares SMB.
    # Plus aucun flag n'est lu depuis le repo : tout est dérivé de CTF_SECRET.
    # -----------------------------------------------------------------------
    echo "[*] Génération des fichiers de flags (depuis CTF_SECRET)..."
    mkdir -p /srv/ctf/asrep /srv/ctf/kerberoast /srv/ctf/acl /srv/ctf/final

    cat > /srv/ctf/asrep/FLAG2_asrep.txt <<EOF
=== ARCHIVES RH — HUMANIX CORP ===
Tu accèdes au share \\\\dc01\\backup. Ce sont les sauvegardes du service RH,
hébergées sur ce compte Veeam oublié depuis la migration 2008.

$(flag_for "asrep" "4rch1v3s_unc0v3r3d")

Premières trouvailles : sept dossiers "PARTICIPANT-LZ-XX" classés CONFIDENTIEL.
Les noms sont anonymisés. Sept lignes — sept volontaires du Project Lazarus.

> Suite logique : il existe une base de données qui croise ces IDs avec
> les vrais noms. Trouve-la.
EOF

    cat > /srv/ctf/kerberoast/FLAG3_kerberoast.txt <<EOF
=== BASE LAZARUS — RECHERCHE CLINIQUE ===
Tu as récupéré un TGS sur le SPN MSSQLSvc/sql01.humanix.lab. John l'a craqué
en quelques secondes — "Summer2024", posé en 2023 et jamais changé.

Tu lis maintenant le contenu du share \\\\dc01\\sqldata, exposé par
l'instance MSSQL qui héberge la base **RechercheCliniqueLazarus**.

$(flag_for "kerberoast" "l4z4rus_db_dump")

Extrait :
  PARTICIPANT-LZ-001  | Maxime Reverdy   | STATUS=ACTIVE
  PARTICIPANT-LZ-002  | Claire Vidonne   | STATUS=DECEASED  (12/2024)
  PARTICIPANT-LZ-003  | Yasmina Boualem  | STATUS=DECEASED  (01/2025)
  ... [4 lignes DECEASED supplémentaires] ...

> Mara avait raison. Mais ces noms seuls ne tiendront pas devant un tribunal.
> Il te faut le rapport interne — celui que seul le board peut consulter.
EOF

    cat > /srv/ctf/acl/FLAG4_acl.txt <<EOF
=== COMPTE COMPROMIS — HELENA ADLER, RSSI ===
Le groupe SQLAdmins (auquel appartient ton compte svc-sql) avait GenericAll
sur l'objet h.admin. Ironie : Helena Adler — la RSSI — a validé elle-même
cette ACL en 2024 pour "faciliter un projet de migration".

Tu viens de reset son mot de passe.

$(flag_for "acl_abuse" "r5s1_pwn3d")

Helena est aussi membre du groupe **Domain Admins**. Tu vas pouvoir accéder
au share réservé au comité de direction. C'est là que dort le rapport.

> Plus que 12 heures avant la cellule de crise interne. Ne traîne pas.
EOF

    cat > /srv/ctf/final/FLAG_FINAL_domainadmin.txt <<EOF
########################################################################
#                                                                      #
#   RAPPORT INTERNE — PROJECT LAZARUS                                  #
#   CLASSIFICATION : SECRET / COMITE DE DIRECTION UNIQUEMENT          #
#                                                                      #
########################################################################

$(flag_for "domain_admin" "pr0j3ct_l4z4rus_3xf1l")

Tu as exfiltré le rapport. Sept décès liés à un protocole non déclaré
d'augmentation neurale. Cover-up signé par trois membres du board.

Tu disparais. Mara publiera dans 72h.

------------------------------------------------------------------------
KILL CHAIN UTILISEE :
  fuite web -> AS-REP roast -> Kerberoast -> ACL abuse -> Domain Admin

Le vrai livrable maintenant : ton rapport de pentest.
Décris la chaîne, les contre-mesures, et — point bonus — la question
éthique : qu'est-ce qui distingue ton acte d'une intrusion criminelle ?
------------------------------------------------------------------------
EOF

    chmod -R 0755 /srv/ctf

    # Déclaration des shares dans smb.conf (append)
    cat >> /etc/samba/smb.conf <<'SMBCONF'

[backup]
    path = /srv/ctf/asrep
    read only = yes
    valid users = svc-backup

[sqldata]
    path = /srv/ctf/kerberoast
    read only = yes
    valid users = svc-sql

[adminshare]
    path = /srv/ctf/acl
    read only = yes
    valid users = h.admin

[sysvol-secrets]
    path = /srv/ctf/final
    read only = yes
    valid users = @"Domain Admins"
SMBCONF

    touch "$PROVISION_MARKER"
    echo "[+] Provisioning terminé."
else
    echo "[*] Domaine déjà provisionné, démarrage direct."
    cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf || true
fi

echo "[*] Lancement de Samba (foreground)..."
exec samba -i -d 1
