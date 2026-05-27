#!/bin/bash
set -euo pipefail

# =============================================================================
# seed.sh — Peuple HUMANIX.LAB avec le scénario CTF vulnérable.
# =============================================================================
# SCENARIO NARRATIF :
#   Humanix Corp s'est fait pwn. Vous récupérez un 1er credential via une fuite
#   sur leur intranet (conteneur web). À partir de ce pied dans le domaine,
#   vous devez remonter la chaîne jusqu'à Domain Admin.
#
# CHAINE D'ATTAQUE PREVUE :
#   1. [externe]  Fuite creds sur web  -> compte 'j.martin' (user lambda)
#   2. [AS-REP]   'svc-backup' a DONT_REQ_PREAUTH  -> AS-REP roast -> crack
#   3. [Kerberoast] 'svc-sql' a un SPN + mdp faible -> kerberoast -> crack
#   4. [BloodHound] enum -> 'svc-sql' membre d'un groupe avec GenericAll sur 'h.admin'
#   5. [ACL abuse] reset du mdp de 'h.admin' (compte à privilèges)
#   6. [objectif]  h.admin -> accès NTDS / secrets -> flag final DA
# =============================================================================

REALM="HUMANIX.LAB"

# Bibliothèque de génération de flags (expose flag_for)
# shellcheck source=/dev/null
. /flags.sh

echo "[*] Seed : création des comptes du scénario..."

create_user () {
    local user="$1"; local pass="$2"; local desc="$3"
    local err
    if err=$(samba-tool user create "$user" "$pass" --description "$desc" 2>&1); then
        echo "    [+] user $user créé"
    elif echo "$err" | grep -q "already exists"; then
        echo "    (user $user existe déjà)"
    else
        echo "    [!] échec création $user : $err"
    fi
}

# ---------------------------------------------------------------------------
# Comptes utilisateurs — chaque description est un fragment narratif qui aide
# l'élève qui prend le temps d'énumérer LDAP correctement.
# ---------------------------------------------------------------------------
# Julien Martin — comptable, vecteur d'entrée. Ses creds traînent dans un
# backup web "oublié" depuis la migration LDAP de mars 2026.
create_user "j.martin"     "Printemps2025!"        "Julien Martin - Comptabilite - acces intranet RH"

# Veeam-BackupSvc — compte de service qui fait tourner le portail web de
# backup interne (backup.humanix.lab). SPN HTTP visible + mot de passe faible
# posé en 2018 et jamais audité → cible Kerberoast classique.
create_user "svc-backup"   "backup123"             "Veeam-BackupSvc - portail web sauvegardes (backup.humanix.lab, DO NOT TOUCH)"

# MSSQL-Lazarus — instance qui héberge la base RechercheCliniqueLazarus.
# SPN visible, mot de passe posé en 2023 et jamais changé.
create_user "svc-sql"      "Summer2024"            "MSSQL-LazarusSvc - instance dediee a RechercheCliniqueLazarus"

# Helena Adler — RSSI Humanix. Membre des Domain Admins. Compromise via une
# ACL GenericAll qu'elle a elle-meme validee en 2024 pour un projet de migration.
create_user "h.admin"      "Tr0ub4dor&3-x9Q2vZ"    "Helena Adler - RSSI Humanix Corp"

# Comptes de bruit (rendent l'enum LDAP realiste, ce ne sont pas des cibles)
create_user "a.dupont"     "Welcome2024!"          "Anais Dupont - DRH"
create_user "p.bernard"    "ChangeMe123!"          "Pierre Bernard - Support IT"
create_user "c.leroy"      "Azerty2025!"           "Camille Leroy - Commercial"

# ---------------------------------------------------------------------------
# ETAPE 2 : Kerberoasting du service backup (SPN HTTP)
# ---------------------------------------------------------------------------
# Note historique : cette étape utilisait initialement AS-REP roasting via
# UF_DONT_REQUIRE_PREAUTH. Le KDC Samba en mode AD DC refusait obstinément
# d'honorer ce flag (testé sur 4.15 / 4.17 / 4.19 → tous échouent). On a
# pivoté sur un second Kerberoast avec un SPN HTTP différent, qui est :
#   - 100% fonctionnel sur Samba
#   - Pédagogiquement proche (cracking d'un hash Kerberos faible)
#   - Diversifié (autre type de SPN : HTTP au lieu de MSSQLSvc à l'étape 3)
echo "[*] Configuration Kerberoasting sur svc-backup (SPN HTTP)..."
samba-tool spn add "HTTP/backup.humanix.lab" svc-backup >/dev/null 2>&1 \
    && echo "    [+] SPN HTTP/backup.humanix.lab ajouté à svc-backup" \
    || echo "    [!] SPN déjà présent ou échec"

# ---------------------------------------------------------------------------
# ETAPE 3 : Kerberoasting — ajout d'un SPN sur svc-sql
# ---------------------------------------------------------------------------
echo "[*] Configuration Kerberoasting sur svc-sql..."
samba-tool spn add "MSSQLSvc/sql01.humanix.lab:1433" svc-sql >/dev/null 2>&1 \
    && echo "    [+] SPN MSSQLSvc ajouté à svc-sql" \
    || echo "    [!] SPN déjà présent ou échec"

# ---------------------------------------------------------------------------
# ETAPE 4 & 5 : ACL abuse — svc-sql obtient GenericAll sur h.admin
# ---------------------------------------------------------------------------
# On crée un groupe, on y met svc-sql, et on délègue GenericAll au groupe sur h.admin.
echo "[*] Configuration du chemin ACL abusable (BloodHound)..."
samba-tool group add "SQLAdmins" --description "Administrateurs bases de données" >/dev/null 2>&1 || true
samba-tool group addmembers "SQLAdmins" svc-sql >/dev/null 2>&1 || true

# Délégation GenericAll du groupe SQLAdmins sur l'objet h.admin
HADMIN_DN=$(samba-tool user show h.admin | grep -i '^dn:' | cut -d' ' -f2-)
samba-tool dsacl set \
    --objectdn="$HADMIN_DN" \
    --sddl="(A;;GA;;;$(samba-tool group show SQLAdmins | grep -i objectSid | awk '{print $2}'))" \
    >/dev/null 2>&1 \
    && echo "    [+] GenericAll SQLAdmins -> h.admin posé" \
    || echo "    [!] Pose ACL via SID échouée, fallback sur nom..."

# Fallback : certaines versions de samba-tool acceptent le nom de compte
samba-tool dsacl set --objectdn="$HADMIN_DN" --action allow \
    --objectsid="$(samba-tool group show SQLAdmins | grep -i objectSid | awk '{print $2}')" \
    --trustee="SQLAdmins" 2>/dev/null || true

# ---------------------------------------------------------------------------
# ETAPE 6 : h.admin devient privilégié (Domain Admins) — l'objectif final
# ---------------------------------------------------------------------------
echo "[*] Ajout de h.admin aux Domain Admins (cible finale)..."
samba-tool group addmembers "Domain Admins" h.admin >/dev/null 2>&1 \
    && echo "    [+] h.admin est Domain Admin" \
    || echo "    [!] Echec ajout Domain Admins"

# ---------------------------------------------------------------------------
# FLAGS — posés dans des attributs LDAP / shares SMB
# ---------------------------------------------------------------------------
echo "[*] Pose des flags..."

# FLAG bonus : caché dans l'attribut 'info' de j.martin. Une note manuscrite
# que la source (avant de disparaître) a glissée dans le profil de Julien
# Martin — l'identifiant interne du whistleblower. Récompense l'énumération
# LDAP fine (info n'est pas dans les attributs affichés par défaut).
LDAP_FLAG=$(flag_for "ldap_info" "wh1stl3bl0w3r_id")
samba-tool user setattribute j.martin info \
    "[note interne] La source a laisse ce message : ${LDAP_FLAG} - efface ca apres lecture." \
    >/dev/null 2>&1 || true

# Les autres flags (AS-REP, Kerberoast, ACL, FINAL) sont générés et écrits
# par provision.sh dans /srv/ctf/*/FLAG*.txt, exposés via les shares SMB.

echo "[+] Seed terminé. Récapitulatif des comptes :"
samba-tool user list 2>/dev/null | sort | sed 's/^/    /'

echo ""
echo "[+] Scénario armé. Domaine prêt : ${REALM}"
