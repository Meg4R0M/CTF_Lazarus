<?php
// =============================================================================
// Humanix Corp — Portail Intranet (volontairement vulnérable)
// =============================================================================
// Vuln pédagogique : un endpoint de "debug" oublié en prod expose un commentaire
// HTML + un fichier de backup accessible qui contient un credential du domaine.
// =============================================================================
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <title>Humanix Corp — Intranet</title>
    <style>
        :root {
            --bg: #0a0e14;
            --fg: #e8f0ee;
            --accent: #5fd9a6;
            --accent-dim: #2f7a5a;
            --muted: #6b8a82;
            --border: #1f6f43;
            --warn: #ffb86c;
        }
        * { box-sizing: border-box; }
        body {
            font-family: 'SF Mono', 'Menlo', monospace;
            background: var(--bg);
            color: var(--fg);
            margin: 0;
            min-height: 100vh;
        }
        .topbar {
            background: linear-gradient(90deg, #0e1822 0%, #122a22 100%);
            padding: 12px 32px;
            border-bottom: 1px solid var(--border);
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 13px;
        }
        .topbar .brand { color: var(--accent); font-weight: bold; letter-spacing: 2px; }
        .topbar .badge {
            color: var(--warn);
            font-size: 11px;
            border: 1px solid var(--warn);
            padding: 2px 8px;
            border-radius: 3px;
        }
        .wrap {
            max-width: 880px;
            margin: 60px auto;
            padding: 24px;
        }
        h1 { color: var(--accent); border-bottom: 1px solid var(--accent-dim); padding-bottom: 8px; }
        h2 { color: var(--accent); font-size: 16px; margin-top: 32px; }
        .panel {
            background: #0e1620;
            border: 1px solid var(--border);
            border-radius: 6px;
            padding: 24px;
            margin: 16px 0;
        }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
        @media (max-width: 720px) { .grid { grid-template-columns: 1fr; } }
        input, button {
            background: #050a10;
            color: var(--fg);
            border: 1px solid var(--accent-dim);
            padding: 8px 12px;
            font-family: inherit;
            font-size: 14px;
            width: 100%;
            margin-bottom: 8px;
            border-radius: 3px;
        }
        button {
            background: var(--accent-dim);
            color: #0a0e14;
            font-weight: bold;
            cursor: pointer;
        }
        .news { border-left: 2px solid var(--accent-dim); padding-left: 16px; margin: 16px 0; }
        .news .date { color: var(--muted); font-size: 12px; }
        .news .title { color: var(--accent); }
        .footer {
            color: var(--muted);
            font-size: 11px;
            margin-top: 48px;
            text-align: center;
            border-top: 1px solid #1a2a24;
            padding-top: 16px;
        }
        a { color: var(--accent); }
        code { background: #050a10; padding: 1px 5px; border-radius: 2px; color: var(--accent); }
    </style>
</head>
<body>

<div class="topbar">
    <div class="brand">&#9650; HUMANIX CORP</div>
    <div><span class="badge">CONFIDENTIEL &mdash; USAGE INTERNE</span></div>
</div>

<div class="wrap">
    <h1>Portail Intranet &mdash; Bienvenue</h1>
    <p style="color: var(--muted);">
        Humanix Corp &middot; Augmentation neurale &middot; <em>&laquo; Beyond the limits of the human mind &raquo;</em>
    </p>

    <div class="grid">
        <div class="panel">
            <h2>// Connexion personnel</h2>
            <form method="post" action="login.php">
                <input type="text" name="user" placeholder="identifiant @humanix.lab" autocomplete="off">
                <input type="password" name="pass" placeholder="mot de passe">
                <button>Authentification AD</button>
            </form>
            <p style="font-size: 11px; color: var(--muted); margin-top: 8px;">
                Authentification Active Directory &middot; domaine <code>HUMANIX.LAB</code><br>
                En cas de probl&egrave;me : ticket ServiceDesk &rarr; Pierre Bernard (Support IT).
            </p>
        </div>

        <div class="panel">
            <h2>// Actualités internes</h2>
            <div class="news">
                <div class="date">12/03/2026 &mdash; Service IT</div>
                <div class="title">Migration LDAP termin&eacute;e</div>
                <p style="font-size: 13px;">
                    La migration de l'annuaire est termin&eacute;e. Tous les comptes ont &eacute;t&eacute;
                    rebascul&eacute;s sur <code>dc01.humanix.lab</code>. Pensez &agrave; v&eacute;rifier
                    vos acc&egrave;s aux partages m&eacute;tier.
                </p>
            </div>
            <div class="news">
                <div class="date">28/02/2026 &mdash; Comit&eacute; de Direction</div>
                <div class="title">Project Lazarus &mdash; Phase II</div>
                <p style="font-size: 13px;">
                    La phase II du programme de recherche entre dans sa fen&ecirc;tre
                    d&eacute;cisive. Rappel : toute communication externe sur Lazarus est
                    strictement <strong>interdite</strong> sans validation board.
                </p>
            </div>
            <div class="news">
                <div class="date">15/02/2026 &mdash; RH</div>
                <div class="title">Cellule de soutien</div>
                <p style="font-size: 13px;">
                    Suite aux r&eacute;cents d&eacute;parts anticip&eacute;s au sein de l'&eacute;quipe Lazarus,
                    une cellule de soutien psychologique est ouverte chaque lundi
                    en salle B-204.
                </p>
            </div>
        </div>
    </div>

    <!-- TODO: retirer avant la mise en prod. Sauvegarde de conf migrée vers /backup/ -->
    <!-- DEBUG: migration LDAP OK le 12/03 — config archivée dans /backup/config.bak.txt -->

    <div class="footer">
        Humanix Corp &copy; 2026 &mdash; Tous droits r&eacute;serv&eacute;s<br>
        DC: dc01.humanix.lab &middot; Domaine: HUMANIX &middot; Site : Issy-les-Moulineaux<br>
        <em>&laquo; Pousser les limites &mdash; &eacute;thiquement. &raquo;</em>
    </div>
</div>

</body>
</html>
