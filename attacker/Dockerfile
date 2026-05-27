FROM kalilinux/kali-rolling

# =============================================================================
# Humanix CTF — Conteneur attaquant (poste de l'élève)
# =============================================================================
# Base : kali-rolling (multi-arch amd64/arm64) — tous les outils offensifs
# sont packagés en .deb par Offensive Security, pas de compilation Rust/C
# requise même sur Apple Silicon. Build = ~30s.
#
# Pré-équipé : netexec, impacket-scripts, bloodhound.py, john, nmap, smbclient...
# C'est depuis ce conteneur que l'élève mène toute la kill-chain.
# =============================================================================

ENV DEBIAN_FRONTEND=noninteractive

# Force le mirror CDN `kali.download` au lieu du round-robin `http.kali.org`
# qui peut servir des index dé-synchronisés (404 sur des .deb pendant le sync).
RUN echo 'deb http://kali.download/kali kali-rolling main contrib non-free non-free-firmware' \
        > /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
        # --- Outils offensifs (prebuilt par Kali) ---
        netexec \
        python3-impacket \
        impacket-scripts \
        bloodhound.py \
        john \
        # --- AD / Kerberos / SMB / LDAP ---
        krb5-user \
        smbclient \
        samba-common-bin \
        ldap-utils \
        dnsutils \
        # --- Network ---
        nmap \
        ncat \
        # --- Confort shell ---
        curl wget git \
        iproute2 iputils-ping \
        vim less \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# krb5.conf pointant vers le realm du lab (l'élève peut kinit directement)
RUN printf '[libdefaults]\n\
    default_realm = HUMANIX.LAB\n\
    dns_lookup_realm = false\n\
    dns_lookup_kdc = false\n\
[realms]\n\
    HUMANIX.LAB = {\n\
        kdc = dc01.humanix.lab\n\
        admin_server = dc01.humanix.lab\n\
    }\n\
[domain_realm]\n\
    .humanix.lab = HUMANIX.LAB\n\
    humanix.lab = HUMANIX.LAB\n' > /etc/krb5.conf

# Wordlist d'amorçage (les mdp faibles du lab sont dedans + bruit)
COPY wordlist.txt /opt/wordlist.txt

# Helpers in-shell : motd, arsenal, briefing, targets, kerberoast
COPY bin/motd       /usr/local/bin/motd
COPY bin/arsenal    /usr/local/bin/arsenal
COPY bin/briefing   /usr/local/bin/briefing
COPY bin/targets    /usr/local/bin/targets
COPY bin/kerberoast /usr/local/bin/kerberoast
RUN chmod +x /usr/local/bin/motd /usr/local/bin/arsenal \
             /usr/local/bin/briefing /usr/local/bin/targets \
             /usr/local/bin/kerberoast

# MOTD + alias confort à chaque ouverture de shell interactif
COPY bashrc.append /tmp/bashrc.append
RUN cat /tmp/bashrc.append >> /etc/bash.bashrc \
 && cat /tmp/bashrc.append >> /root/.bashrc \
 && rm /tmp/bashrc.append

WORKDIR /root
CMD ["sleep", "infinity"]
