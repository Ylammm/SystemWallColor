# SystemWallColor

Synchronisation automatique des thèmes système avec le fond d'écran sur **COSMIC Desktop** (Pop!_OS).

Dès que vous changez de wallpaper ou de mode clair/sombre dans COSMIC, SystemWallColor :
1. Génère un thème COSMIC assorti avec [Matugen](https://github.com/InioX/matugen) et l'applique automatiquement
2. Génère une palette de couleurs terminal avec [Pywal](https://github.com/dylanaraps/pywal)
3. Synchronise le thème de Firefox avec [Pywalfox](https://github.com/Frewacom/pywalfox)

Le tout tourne en arrière-plan via un service **systemd** qui surveille les changements en temps réel.

## Prérequis

- **Pop!_OS avec COSMIC Desktop** (ou toute distribution utilisant COSMIC)
- Accès `sudo` (pour l'installation des dépendances système)
- Firefox (optionnel, uniquement si vous voulez la synchronisation du thème navigateur)

## Installation

```bash
git clone https://gitlab.com/Ylamm/systemwallcolor.git
cd systemwallcolor
chmod +x install.sh
./install.sh
```

Le script `install.sh` s'occupe de :
- Installer les dépendances système (`inotify-tools`, `python3-pip`, `pipx`)
- Installer Rust/Cargo si absent, puis compiler `matugen`
- Installer `pywal` et `pywalfox`
- Copier les fichiers du projet dans `~/.local/bin/SystemWallColor/`
- Installer et activer le service systemd utilisateur (`cosmic-watch.service`)

Si vous utilisez Firefox, installez également l'extension [Pywalfox](https://addons.mozilla.org/en-US/firefox/addon/pywalfox/) depuis le store officiel.

> ⚠️ **Au premier lancement**, changez une première fois de fond d'écran pour que le service détecte le changement et applique le thème initial.

## Fonctionnement

| Composant | Rôle |
|---|---|
| `swcw.sh` | Surveille les fichiers de configuration COSMIC via `inotifywait` |
| `swc.py` | Exécuté à chaque changement détecté ; orchestre Matugen, Pywal, Pywalfox et l'application du thème |
| `cosmic-watch.service` | Service systemd utilisateur qui garde `swcw.sh` actif en permanence |

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

- Fonctionne uniquement avec **COSMIC Desktop** (dépend de `cosmic-settings` et des fichiers de config spécifiques à COSMIC).
- La synchronisation Firefox nécessite que le navigateur soit ouvert et l'extension Pywalfox installée côté navigateur.
- **Les couleurs internes de cosmic-term (fond, texte) ne peuvent pas être automatisées actuellement.** cosmic-term ne recharge pas son thème même si le fichier de configuration est modifié en arrière-plan. Pour appliquer manuellement les nouvelles couleurs :
  1. Ouvrez cosmic-term
  2. **View → Color schemes... → Import**

     <img src="Terminal_Couleur_Aide.png" alt="Import d'un thème dans cosmic-term" width="30%">
  3. Sélectionnez `~/.cache/wal/cosmic_term.ron`
  4. Sélectionnez le thème "Pywal" dans la liste

## Licence

Projet personnel, libre d'utilisation et de modification.