# 🎯 Humanix — Project Lazarus

> **Message chiffré reçu — Signal — 02h47**
> *Expéditeur : Mara Aldritch / The Lighthouse Foundation*

---

> Salut.
>
> Tu te souviens de ce que je t'avais dit sur **Humanix Corp** ? Le biotech
> qui fait des implants neuronaux ? Vitrine éthique impeccable, conférences
> TED, présence à Davos.
>
> J'avais une source à l'intérieur. Trois semaines de discussions chiffrées.
> Elle m'avait envoyé des fragments — assez pour qu'on comprenne qu'il y a
> un programme parallèle, **Project Lazarus**, des essais cliniques humains
> non déclarés.
>
> Sept noms étaient sortis. Sept volontaires.
>
> **Elle a cessé de répondre il y a 36 heures.**
>
> Avant de disparaître, elle a eu le temps de me dire qu'elle avait laissé
> *« quelque chose dans le profil d'un collègue de compta »* sur leur
> intranet, et que *« la sauvegarde de la dernière migration LDAP traîne
> encore en clair »*. C'est tout ce que j'ai.
>
> Je te commissionne. Tu as **72 heures** avant que leur cellule de crise
> ne nettoie tout. Objectif :
>
> 1. Pénétrer leur SI à partir de l'intranet exposé.
> 2. Remonter la chaîne jusqu'aux **Domain Admins**.
> 3. Exfiltrer le rapport interne du Project Lazarus.
> 4. Disparaître. Aucune trace, aucune compromission qui pourrait
>    invalider la publication.
>
> Tout est dans le périmètre autorisé que je t'ai envoyé.
> N'en sors pas. Le reste du monde est hors-jeu.
>
> Bonne chasse.
> — M.

---

## 🌐 Périmètre autorisé

| Cible | IP | Notes |
|---|---|---|
| Intranet Humanix | `172.31.0.20` (HTTP) | Point d'entrée — réseau externe |
| Domain Controller | `172.30.0.10` (`dc01.humanix.lab`) | Samba4 AD DS — réseau interne |
| Domaine | `HUMANIX.LAB` (NetBIOS: `HUMANIX`) | |

Hors-périmètre : **tout le reste**. C'est un lab isolé, mais ce
disclaimer-réflexe — *« je vérifie ce que je peux toucher avant d'agir »* —
fait partie du métier.

**Cadre légal (rappel)** : les techniques pratiquées ici sont identiques à
celles utilisées en attaque réelle. Hors d'un mandat ou d'un lab autorisé,
c'est **art. 323-1 à 323-7 du Code pénal** : jusqu'à 5 ans de prison,
150 000 € d'amende.

---

## 🎯 Objectifs

5 flags principaux + 1 bonus, posés à chaque étape de la kill-chain.
Le rapport final compte autant que les flags eux-mêmes.

| # | Trophée | Indice (en clair) |
|---|---|---|
| 1 | `FLAG{l34k_conf1rm3d_...}` | La source a parlé d'une "sauvegarde de migration LDAP en clair". |
| 2 | `FLAG{4rch1v3s_unc0v3r3d_...}` | Un compte de service oublié donne accès aux archives RH. |
| 3 | `FLAG{l4z4rus_db_dump_...}` | La base clinique se cache derrière un service applicatif. |
| 4 | `FLAG{r5s1_pwn3d_...}` | Une relation d'autorité mal pensée mène à la RSSI. |
| 5 | `FLAG{pr0j3ct_l4z4rus_3xf1l_...}` | Le rapport. Ce pour quoi tu es là. |
| bonus | `FLAG{wh1stl3bl0w3r_id_...}` | *« La source a laissé une note dans le profil d'un collègue de compta. »* |

Le suffixe (`...`) est unique à ton instance — tu ne peux pas le deviner
sans avoir réellement fait l'étape.

---

## 🖥️ Ton poste

Un conteneur Linux pré-équipé avec tout ce qu'il te faut.
Lance-le :

```bash
make shell-attacker
```

Une fois dans le shell, tape :

```bash
briefing    # rappelle-toi de la mission
arsenal     # liste les outils à ta disposition
targets     # liste les cibles et leurs IP
```

---

## 🐳 Compatibilité Exegol

Si tu préfères ton **Exegol** habituel à l'attaquant fourni, c'est possible.
Le lab Humanix expose deux réseaux Docker :

- `humanix-ctf-ad_lab_external` (172.31.0.0/24) — pour atteindre l'intranet
- `humanix-ctf-ad_lab_internal` (172.30.0.0/24) — pour atteindre le DC

### Procédure

```bash
# 1. Démarre le lab côté instructeur / sur ta machine
make up

# 2. Démarre ton Exegol (depuis l'host, pas depuis le lab)
exegol start lazarus-recon nightly

# 3. Branche ton Exegol aux deux réseaux du lab
docker network connect humanix-ctf-ad_lab_external exegol-lazarus-recon
docker network connect humanix-ctf-ad_lab_internal exegol-lazarus-recon

# 4. Dans Exegol, pointe ton DNS vers le DC (sinon Kerberos casse)
echo "nameserver 172.30.0.10" | sudo tee /etc/resolv.conf

# 5. Vérifie : tu dois voir le web ET le DC
curl http://172.31.0.20/
nxc smb 172.30.0.10
```

> ⚠️ Sur Apple Silicon (M1/M2/M3) : Exegol nightly arm64 fonctionne mais
> certains binaires peuvent demander de l'émulation. L'attaquant fourni
> (`make shell-attacker`) est natif arm64, c'est en général plus fluide.

### Note Kerberos

Le krb5.conf dans Exegol par défaut ne connaît pas `HUMANIX.LAB`.
Ajoute dans `/etc/krb5.conf` :

```ini
[libdefaults]
    default_realm = HUMANIX.LAB
    dns_lookup_realm = false
    dns_lookup_kdc = false
[realms]
    HUMANIX.LAB = {
        kdc = dc01.humanix.lab
        admin_server = dc01.humanix.lab
    }
[domain_realm]
    .humanix.lab = HUMANIX.LAB
    humanix.lab = HUMANIX.LAB
```

---

Bonne chasse. Et n'oublie pas : **le rapport, c'est le métier.**
