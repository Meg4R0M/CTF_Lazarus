FROM ubuntu:22.04

# =============================================================================
# Humanix CTF — Domain Controller (Samba4 AD DS)
# Domaine : HUMANIX.LAB  /  NetBIOS : HUMANIX
# =============================================================================
# NOTE PEDAGOGIQUE : cette image monte un vrai KDC Kerberos + LDAP + SMB via
# Samba4 en mode "AD DC". Ce N'EST PAS un Windows Server : pas d'ADCS, pas de
# GPO Windows natives. Mais Kerberoasting, AS-REP roasting, enum LDAP,
# BloodHound et le mouvement latéral SMB fonctionnent de façon réaliste.
#
# BASE : ubuntu:22.04 (Samba 4.15) — sweet spot LTS connu :
#   - Samba 4.13 et avant : trop ancien, manque d'outils modernes
#   - Samba 4.15 (Ubuntu 22.04 LTS) : AS-REP roast + Kerberoast OK, support LTS
#     jusqu'en 2027
#   - Samba 4.17 (Debian 12)        : Kerberoast OK, AS-REP roast CASSE
#                                     (DONT_REQ_PREAUTH ignoré par le KDC)
#   - Samba 4.19 (Ubuntu 24.04)     : les deux CASSES (FAST armoring + checksum
#                                     hardening). Pas exploitable en lab CTF.
#
# Build context : racine du repo (compose le passe via context: .)
# =============================================================================

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        samba \
        samba-dsdb-modules \
        samba-vfs-modules \
        python3-samba \
        smbclient \
        krb5-user \
        krb5-config \
        winbind \
        libnss-winbind \
        libpam-winbind \
        dnsutils \
        ldb-tools \
        python3 \
        procps \
        iproute2 \
        net-tools \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# On supprime la conf smb.conf par défaut : 'samba-tool domain provision'
# refuse de s'exécuter si un smb.conf existe déjà.
RUN rm -f /etc/samba/smb.conf

COPY dc/provision.sh /provision.sh
COPY dc/seed.sh /seed.sh
COPY flags.sh /flags.sh
RUN chmod +x /provision.sh /seed.sh /flags.sh

EXPOSE 53/tcp 53/udp 88/tcp 88/udp 135/tcp 139/tcp 389/tcp 389/udp 445/tcp 464/tcp 464/udp 636/tcp 3268/tcp 3269/tcp

ENTRYPOINT ["/provision.sh"]
