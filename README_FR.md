# SystemWallColor

*[English version](README.md)*

![Showcase](showcase.gif)

Synchronisation automatique du thème système avec votre fond d'écran sur **COSMIC Desktop** (Pop!_OS).

À chaque changement de fond d'écran ou de mode clair/sombre dans COSMIC, SystemWallColor :
1. Génère un thème COSMIC assorti avec [Matugen](https://github.com/InioX/matugen) et l'applique automatiquement
2. Génère une palette de couleurs terminal avec [Pywal](https://github.com/dylanaraps/pywal)
3. Synchronise le thème de Firefox avec [Pywalfox](https://github.com/Frewacom/pywalfox)
4. Génère des thèmes clair/sombre assortis pour l'éditeur [Zed](https://zed.dev)

Tout fonctionne en arrière-plan via un service **systemd** qui surveille les changements en temps réel.

## Prérequis

- **Pop!_OS avec COSMIC Desktop** (ou toute distribution utilisant COSMIC)
- Accès `sudo` (pour l'installation des dépendances système)
- Firefox (optionnel, uniquement si vous voulez la synchronisation du thème du navigateur)
- Zed (optionnel, uniquement si vous voulez la synchronisation du thème de l'éditeur)

## Installation

```bash
git clone https://gitlab.com/Ylamm/systemwallcolor.git
cd systemwallcolor
chmod +x install.sh
./install.sh
```

Le script `install.sh` se charge de :
- Installer les dépendances système (`inotify-tools`, `python3-pip`, `pipx`)
- Installer Rust/Cargo si absent, puis compiler `matugen`
- Installer `pywal` et `pywalfox`
- Copier les fichiers du projet dans `~/.local/bin/SystemWallColor/`
- Installer et activer le service systemd utilisateur (`cosmic-watch.service`)
- Mettre en place les templates Matugen pour COSMIC et Zed

Si vous utilisez Firefox, installez également l'extension [Pywalfox](https://addons.mozilla.org/en-US/firefox/addon/pywalfox/) depuis le store officiel.

> ⚠️ **Au premier lancement**, changez une fois votre fond d'écran pour que le service détecte le changement et applique le thème initial.

## Fonctionnement

| Composant | Rôle |
|---|---|
| `swcw.sh` | Surveille les fichiers de configuration COSMIC via `inotifywait` |
| `swc.py` | S'exécute à chaque changement détecté ; orchestre Matugen, Pywal, Pywalfox et applique le thème |
| `cosmic-watch.service` | Service systemd utilisateur qui maintient `swcw.sh` actif en permanence |

## Thématisation de l'éditeur Zed

SystemWallColor génère également des thèmes **Zed** assortis ("Matugen Dark" / "Matugen Light") à partir des couleurs de votre fond d'écran.

Au premier lancement, `install.sh` copie les templates (`matugen/templates/zed-colors-dark.json` et `zed-colors-light.json`) et ajoute les sections `[templates.zeddark]` / `[templates.zedlight]` à votre configuration Matugen. Le thème généré est écrit directement dans le chemin de configuration du sandbox Flatpak de Zed (`~/.var/app/dev.zed.Zed/config/zed/themes/`), Zed étant généralement installé via Flatpak sur Pop!_OS.

Pour l'activer dans Zed :
1. Ouvrez la palette de commandes (`ctrl-k ctrl-t`)
2. Sélectionnez **Matugen Dark** ou **Matugen Light**

> ⚠️ Si vous avez installé Zed autrement (binaire natif, apt, snap), modifiez les valeurs `output_path` de `zeddark`/`zedlight` dans `~/.config/matugen/config.toml` pour pointer vers `~/.config/zed/themes/` à la place.

## Vérifier que le service tourne

```bash
systemctl --user status cosmic-watch.service
```

## Suivre les logs en direct

```bash
journalctl --user -u cosmic-watch.service -f
```

## Désinstallation

```bash
systemctl --user disable --now cosmic-watch.service
rm ~/.config/systemd/user/cosmic-watch.service
rm -r ~/.local/bin/SystemWallColor
```

## Limitations connues

- Fonctionne uniquement avec **COSMIC Desktop** (dépend de `cosmic-settings` et des fichiers de configuration spécifiques à COSMIC).
- La synchronisation Firefox nécessite que le navigateur soit ouvert et l'extension Pywalfox installée côté navigateur.
- **Les couleurs internes de cosmic-term (fond, texte) ne peuvent pas être automatisées pour l'instant.** cosmic-term ne recharge pas son thème même si le fichier de configuration est modifié en arrière-plan. Pour appliquer les nouvelles couleurs manuellement :
  1. Ouvrez cosmic-term
  2. **Affichage → Jeux de couleurs... → Importer**

     <img src="Terminal_Couleur_Aide.png" alt="Import d'un thème dans cosmic-term" width="30%">
  3. Sélectionnez `~/.cache/wal/cosmic_term.ron`
  4. Sélectionnez le thème "Pywal" dans la liste
- **La synchronisation du thème Zed nécessite un redémarrage de Zed** après la première génération pour que le nouveau thème apparaisse dans le sélecteur de thème. Les changements de fond d'écran suivants mettent à jour le fichier de thème directement, sans nécessiter de redémarrage.

## Licence

Projet personnel, libre d'utilisation et de modification.

## Source

Les templates matugen pour Zed sont inspirés de https://github.com/InioX/matugen-themes/blob/main/templates/zed-colors.json
Le template matugen pour Obsidian provient de https://github.com/Simorg2002/obsidian-matugen-template/tree/main
