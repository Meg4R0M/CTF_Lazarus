# ▲ Humanix — Project Lazarus

> **CTF Active Directory** thématique sur fond de biotech & lanceurs d'alerte.
> **Portable, reproductible, Docker-only.** Aucun Windows requis. Conçu pour public **Master 2 / pro**.
>
> Chaîne d'attaque : **recon web externe → Kerberoast HTTP service → Kerberoast MSSQL → BloodHound → ACL abuse → Domain Admin**.
> Socle technique : **Samba4 en mode AD DC** conteneurisé.

```
recon web → Kerberoast (HTTP) → Kerberoast (MSSQL) → BloodHound → ACL abuse → Domain Admin
```

---

## 🎬 Scénario

**Humanix Corp** est un biotech leader en augmentation neurale. Vitrine éthique
impeccable... officiellement. **Project Lazarus** — essais cliniques humains non
déclarés — fait sept morts en 18 mois.

Une journaliste, **Mara Aldritch**, perd contact avec sa source à l'intérieur de
Humanix. Avant de disparaître, la source mentionne deux indices : *« la sauvegarde
de la dernière migration LDAP traîne encore en clair »*, et *« j'ai laissé quelque
chose dans le profil d'un collègue de compta »*.

Tu as 72 heures pour pénétrer leur SI, remonter la chaîne jusqu'aux **Domain
Admins**, exfiltrer le rapport interne — et disparaître.

> Briefing complet : [ENONCE_ELEVE.md](ENONCE_ELEVE.md)

---

## ⚠️ Cadre légal & éthique

Ce lab est **volontairement vulnérable**. Il est conçu pour tourner **isolé** :
le réseau `lab_internal` est en mode `internal: true` (aucun accès Internet sortant).

- Usage **strictement pédagogique**, sur ce périmètre fictif uniquement.
- Les techniques pratiquées ici (AS-REP roasting, Kerberoasting, ACL abuse, etc.)
  sont **identiques à celles utilisées en attaque réelle**. Les employer hors d'un
  périmètre explicitement autorisé (mandat de pentest signé, lab perso) constitue
  une **infraction pénale** — France : articles **323-1 à 323-7 du Code pénal**
  (atteinte aux STAD), jusqu'à 5 ans d'emprisonnement et 150 000 € d'amende.
- Le réflexe « je vérifie mon périmètre et mon autorisation avant d'agir » est une
  **compétence métier**, pas une formalité.

---

## 🚀 Démarrage rapide

```bash
git clone git@github.com:Meg4R0M/CTF_Lazarus.git
cd CTF_Lazarus

make up               # build + démarre (DC, intranet web, poste de pentest)
                      # crée .env automatiquement (secret aléatoire si absent)
make logs             # suit le provisioning du DC (~60-90s)
make briefing         # affiche le briefing de mission
make shell-attacker   # ouvre ton poste de pentest

make help             # liste des commandes
```

**Prérequis** : Docker + plugin `docker compose`. ~2-3 Go RAM suffisent
(vs 32-64 Go pour GOAD). Compatible amd64 et arm64 (Apple Silicon).

---

## 🗺️ Topologie

```
   [ poste pentest ]          réseau EXTERNE (172.31.0.0/24)
   humanix-attacker  ───────────────┬───────────────────────
   172.31.0.30                       │
   172.30.0.30                  humanix-web (intranet)
        │                       172.31.0.20
        │
        │  réseau INTERNE (172.30.0.0/24, --internal, no Internet)
        └───────────────────────────────
                                  humanix-dc01 (Samba4 AD DC)
                                  172.30.0.10  /  dc01.humanix.lab
```

Le poste de pentest est sur **les deux réseaux** : pédagogiquement, il « voit »
d'abord le web (externe), et le pivot vers le DC (interne) simule l'entrée dans le SI.

---

## 🎯 Objectifs

5 flags principaux + 1 bonus. L'objectif final = Domain Admin **et** exfiltration
du rapport.

| # | Flag (thème narratif) | Points |
|---|--------------|--------|
| 1 | `FLAG{l34k_conf1rm3d_...}` — fuite confirmée | 10 |
| 2 | `FLAG{4rch1v3s_unc0v3r3d_...}` — archives RH | 20 |
| 3 | `FLAG{l4z4rus_db_dump_...}` — base clinique | 20 |
| 4 | `FLAG{r5s1_pwn3d_...}` — RSSI compromise | 25 |
| 5 | `FLAG{pr0j3ct_l4z4rus_3xf1l_...}` — rapport exfiltré | 25 |
| bonus | `FLAG{wh1stl3bl0w3r_id_...}` — identité du whistleblower | 5 |

> Le suffixe des flags est unique par instance (dérivé d'un secret formateur).
> Les valeurs ci-dessus sont des **modèles** — la vraie valeur dépend du
> `CTF_SECRET` de ton instance.

---

## 🔐 Modèle de génération des flags

Aucun flag n'est en clair dans le repo. Chaque flag est dérivé au démarrage du DC :

```
FLAG{<theme>_<sha256(CTF_SECRET:stage)[0:12]>}
```

Conséquences pédagogiques :
- Cloner le repo nu **ne révèle aucun flag**.
- Changer `CTF_SECRET` dans `.env` puis `make reset` → tous les flags changent.
- Idéal pour ré-armer un sujet unique entre deux promos (anti-partage).

Détails dans [.env.example](.env.example).

---

## 🐳 Compatibilité Exegol

Les élèves qui préfèrent leur **Exegol** habituel peuvent l'utiliser à la place
du poste fourni. Procédure complète dans
[ENONCE_ELEVE.md](ENONCE_ELEVE.md#-compatibilité-exegol).

Résumé :
```bash
docker network connect humanix-ctf-ad_lab_external <ton-exegol>
docker network connect humanix-ctf-ad_lab_internal <ton-exegol>
# puis dans Exegol : echo "nameserver 172.30.0.10" > /etc/resolv.conf
```

---

## 🎓 Pour les formateurs

Le **walkthrough complet**, le **writeup PDF**, la **gestion du secret formateur**
et les **commandes de debug** ne sont volontairement **pas dans le repo public**
(pour ne pas spoiler les étudiants qui consultent GitHub).

Si tu es formateur et que tu veux utiliser ce lab pour ton cours :

- 📩 Contact maintainer : [@Meg4R0M](https://github.com/Meg4R0M) (GitHub)
- 📂 Tu recevras hors-git : `INSTRUCTOR.md` (walkthrough complet),
  `docs/WRITEUP_Project_Lazarus.pdf` (rapport façon pentest), et le script
  source du writeup
- 🔧 Côté lab, `make instructor-help` (depuis le repo cloné) liste les commandes
  formateur (affichage des flags de l'instance, debug Samba, génération de
  tarball étudiant, etc.)

---

## 🧩 Pistes d'extension

Idées pour étendre le scénario (niveau "chaud patate +") :

- **RBCD** (Resource-Based Constrained Delegation) entre deux comptes machine
- **Trust cross-domain** (un 2e DC Samba)
- **ADCS / ESC1-8** en branchant une VM Windows hybride (seule vraie limite de Samba4)
- Intégration **CTFd** : chaque flag = challenge avec déblocage progressif

---

## 📜 Licence & crédits

Ce lab est mis à disposition à des fins **pédagogiques uniquement**.
Utilisation hors lab autorisé = infraction pénale (cf. cadre légal ci-dessus).

Maintainer : [@Meg4R0M](https://github.com/Meg4R0M)
