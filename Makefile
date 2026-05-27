# =============================================================================
# Humanix CTF — Makefile de gestion du lab
# =============================================================================

.PHONY: help instructor-help up down reset logs shell-attacker shell-dc status check flags-show student-pack briefing

# Inclut .env si présent — expose CTF_SECRET aux cibles `flags-show` et `student-pack`
ifneq (,$(wildcard .env))
    include .env
    export
endif

# Help "public" (visible aux élèves). Volontairement minimal : aucune mention
# des cibles qui révéleraient les comptes, les flags, ou la solution.
help:
	@echo ""
	@echo "  ▲ HUMANIX — Project Lazarus"
	@echo ""
	@echo "  make up              Démarre le lab (crée .env si absent, build images)"
	@echo "  make down            Arrête le lab (les données sont conservées)"
	@echo "  make reset           Remet tout à neuf (reprovisionne le domaine)"
	@echo "  make status          Etat des conteneurs"
	@echo "  make logs            Logs du DC (suit le provisioning Kerberos)"
	@echo "  make shell-attacker  Ouvre ton poste de pentest"
	@echo "  make briefing        Affiche le briefing de mission"
	@echo ""

# Briefing élève — accessible depuis la racine, montre ENONCE_ELEVE.md
briefing:
	@if [ -f ENONCE_ELEVE.md ]; then \
		cat ENONCE_ELEVE.md; \
	else \
		echo "[!] Briefing introuvable (ENONCE_ELEVE.md manquant)."; \
	fi

# Help formateur — toutes les cibles "dangereuses" ou spoilers vivent ici.
# Pas listé dans `make help`, accessible uniquement à qui sait ce qu'il cherche.
instructor-help:
	@echo ""
	@echo "  ▲ HUMANIX — commandes FORMATEUR (ne pas distribuer)"
	@echo ""
	@echo "  make shell-dc        Shell sur le Domain Controller (debug Samba)"
	@echo "  make check           Vérifie que le scénario est armé (comptes + SPN)"
	@echo "  make flags-show      Affiche les valeurs de flags de l'instance courante"
	@echo "  make student-pack    Produit dist/humanix-ctf-student.tar.gz"
	@echo ""
	@echo "  Variables :"
	@echo "    CTF_SECRET=...     Secret formateur (cf. .env / .env.example)"
	@echo ""

# Crée .env avec un secret aléatoire si absent (cf. .env.example pour la doc)
.env:
	@if [ ! -f .env ]; then \
		if command -v openssl >/dev/null 2>&1; then \
			SECRET=$$(openssl rand -hex 24); \
		else \
			SECRET=$$(head -c 32 /dev/urandom | xxd -p | tr -d '\n'); \
		fi; \
		printf 'CTF_SECRET=%s\n' "$$SECRET" > .env; \
		echo "[+] .env créé avec un secret aléatoire ($$SECRET)."; \
		echo "    Note ce secret quelque part — il détermine les valeurs de flags."; \
	fi

up: .env
	docker compose up -d --build
	@echo ""
	@echo "[+] Lab démarré. Patiente ~60-90s que le DC finisse de provisionner."
	@echo "    Suis le provisioning : make logs"
	@echo "    Briefing mission     : make briefing"
	@echo "    Poste de pentest     : make shell-attacker"

down:
	docker compose down

reset: .env
	docker compose down -v
	docker compose up -d --build
	@echo "[+] Lab réinitialisé à neuf (domaine reprovisionné, flags inchangés tant que CTF_SECRET ne bouge pas)."

status:
	docker compose ps

logs:
	docker compose logs -f dc01

shell-attacker:
	docker exec -it humanix-attacker /bin/bash

shell-dc:
	docker exec -it humanix-dc01 /bin/bash

check:
	@echo "[*] Comptes du domaine :"
	@docker exec humanix-dc01 samba-tool user list 2>/dev/null | sort | sed 's/^/    /' || echo "  DC pas prêt"
	@echo "[*] SPN configurés :"
	@docker exec humanix-dc01 samba-tool spn list svc-sql 2>/dev/null | sed 's/^/    /' || true

# ----------------------------------------------------------------------------
# Affiche les valeurs réelles de flags pour cette instance (utile au formateur
# pour corriger les rendus / valider les soumissions).
# ----------------------------------------------------------------------------
flags-show: .env
	@if [ -z "$(CTF_SECRET)" ]; then echo "[!] CTF_SECRET non défini"; exit 1; fi
	@echo "[*] Flags de l'instance courante (dérivés de CTF_SECRET) :"
	@for entry in \
		"web_recon:l34k_conf1rm3d:FLAG 1 (fuite confirmée — web recon)" \
		"ldap_info:wh1stl3bl0w3r_id:Bonus (identité du whistleblower)" \
		"backup_spn:4rch1v3s_unc0v3r3d:FLAG 2 (archives RH — Kerberoast HTTP)" \
		"kerberoast:l4z4rus_db_dump:FLAG 3 (base Lazarus — Kerberoast)" \
		"acl_abuse:r5s1_pwn3d:FLAG 4 (RSSI compromise — ACL abuse)" \
		"domain_admin:pr0j3ct_l4z4rus_3xf1l:FLAG FINAL (rapport exfiltré — DA)"; do \
		stage=$$(echo $$entry | cut -d: -f1); \
		theme=$$(echo $$entry | cut -d: -f2); \
		label=$$(echo $$entry | cut -d: -f3); \
		hash=$$(printf '%s:%s' "$(CTF_SECRET)" "$$stage" | sha256sum | cut -c1-12); \
		printf "    %-50s FLAG{%s_%s}\n" "$$label" "$$theme" "$$hash"; \
	done

# ----------------------------------------------------------------------------
# Génère un tarball "version étudiant" : code du lab, sans .env, sans flags
# matérialisés, sans walkthrough formateur. Distribuable tel quel.
# ----------------------------------------------------------------------------
student-pack:
	@mkdir -p dist
	@rm -f dist/humanix-ctf-student.tar.gz
	@tar --exclude='.git' \
	     --exclude='.env' \
	     --exclude='INSTRUCTOR.md' \
	     --exclude='INSTRUCTOR_NOTES.md' \
	     --exclude='docs/WRITEUP*' \
	     --exclude='docs/build_writeup.py' \
	     --exclude='dc_data' \
	     --exclude='dist' \
	     --exclude='scripts/flags/*.txt' \
	     --exclude='.DS_Store' \
	     -czf dist/humanix-ctf-student.tar.gz \
	     -C . \
	     --transform 's,^\./,humanix-ctf/,' \
	     .
	@echo "[+] dist/humanix-ctf-student.tar.gz prêt."
	@echo "    Vérifie qu'aucun flag ne fuit :"
	@if tar -tzf dist/humanix-ctf-student.tar.gz | grep -qE '(\.env$$|INSTRUCTOR\.md|FLAG[0-9_]*\.txt)'; then \
		echo "    [!] ATTENTION : artefacts sensibles dans le tarball !"; \
		tar -tzf dist/humanix-ctf-student.tar.gz | grep -E '(\.env$$|INSTRUCTOR\.md|FLAG[0-9_]*\.txt)'; \
		exit 1; \
	else \
		echo "    [+] Aucun artefact sensible détecté."; \
	fi
