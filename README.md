# Humanix — Project Lazarus

> CTF Active Directory thématique sur fond de biotech & lanceurs d'alerte.
> **Portable, reproductible, Docker-only.** Aucun Windows requis.
>
> Chaîne d'attaque : **recon web externe → AS-REP roasting → Kerberoasting → BloodHound → ACL abuse → Domain Admin**.
> Socle technique : **Samba4 en mode AD DC** conteneurisé.

---

## ⚠️ Cadre légal & éthique (à lire et à faire lire aux élèves)

Ce lab est **volontairement vulnérable**. Il est conçu pour tourner **isolé** :
le réseau `lab_internal` est en mode `internal: true` (aucun accès Internet sortant).

- Usage **strictement pédagogique**, sur ce périmètre fictif uniquement.
- Les techniques pratiquées ici (AS-REP roasting, Kerberoasting, ACL abuse, etc.)
  sont **identiques à celles utilisées en attaque réelle**. Les employer hors d'un
  périmètre explicitement autorisé (mandat de pentest signé, lab perso) constitue
  une **infraction pénale** — France : articles **323-1 à 323-7 du Code pénal**
  (atteinte aux STAD), jusqu'à 5 ans d'emprisonnement et 150 000 € d'amende.
- Rappel formateur : ce disclaimer fait partie du livrable. Le réflexe « je vérifie
  mon périmètre et mon autorisation avant d'agir » est une **compétence métier**,
  pas une formalité.

---

## 🚀 Démarrage rapide

```bash
make up          # build + démarre (DC, intranet web, poste attaquant)
                 # crée .env automatiquement si absent (secret aléatoire)
make logs        # suit le provisioning du DC (~60-90s, patiente la 1re fois)
make shell-attacker   # ouvre le shell du poste élève
make reset       # remet tout à neuf (reprovisionne le domaine)
```

Prérequis : Docker + plugin `docker compose`. ~2-3 Go RAM suffisent (vs 32-64 Go pour GOAD).

> 🔐 **Formateur** : les valeurs réelles des flags sont dérivées d'un secret
> dans `.env` (cf. [.env.example](.env.example)). Voir [INSTRUCTOR.md](INSTRUCTOR.md)
> pour le walkthrough, la gestion du secret et `make flags-show`.

---

## 🗺️ Topologie

```
   [ poste élève ]            réseau EXTERNE (172.31.0.0/24)
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

Le poste attaquant est sur **les deux réseaux** : pédagogiquement, il « voit »
d'abord le web (externe), et le pivot vers le DC (interne) simule l'entrée dans le SI.

---

## 🎯 Énoncé (version élève)

> **Humanix Corp** a un intranet exposé. Votre mission : partir de l'extérieur,
> trouver un pied dans le domaine `HUMANIX.LAB`, et remonter la chaîne jusqu'à
> **Domain Admin**. 5 flags jalonnent le parcours. L'objectif final = compromettre
> le domaine ET récupérer le flag final.

Cible web : `http://172.31.0.20` — DC : `dc01.humanix.lab` (172.30.0.10)

Scoring suggéré :
| # | Flag (thème narratif) | Points |
|---|--------------|--------|
| 1 | `FLAG{l34k_conf1rm3d_...}` fuite confirmée | 10 |
| 2 | `FLAG{4rch1v3s_unc0v3r3d_...}` archives RH | 20 |
| 3 | `FLAG{l4z4rus_db_dump_...}` base clinique | 20 |
| 4 | `FLAG{r5s1_pwn3d_...}` RSSI compromise | 25 |
| 5 | `FLAG{pr0j3ct_l4z4rus_3xf1l_...}` rapport exfiltré | 25 |
| bonus | `FLAG{wh1stl3bl0w3r_id_...}` identité du whistleblower | 5 |

> Le suffixe des flags est unique par instance (dérivé du secret formateur),
> donc les valeurs ci-dessus sont des **modèles** — la vraie valeur est
> spécifique à votre `CTF_SECRET`.

---

## 🔓 Walkthrough formateur

→ Déplacé dans [INSTRUCTOR.md](INSTRUCTOR.md) (à ne pas distribuer aux élèves).

---

## 📦 Distribution aux élèves

```bash
make student-pack
# Produit dist/humanix-ctf-student.tar.gz
# Exclut automatiquement : .env, INSTRUCTOR.md, dc_data/, fichiers de flags
# Refuse de générer le tarball si un artefact sensible est détecté
```

- Le lab est **idempotent** : `make reset` rejoue un domaine propre (avec les
  mêmes flags tant que `CTF_SECRET` ne change pas).
- Variante examen : change `CTF_SECRET` dans `.env`, `make reset`. Tous les
  flags changent. 5 sec pour ré-armer un sujet unique.

---

## 🧩 Pistes d'extension

Voir [INSTRUCTOR.md](INSTRUCTOR.md#-pistes-dextension-niveau-chaud-patate-).
