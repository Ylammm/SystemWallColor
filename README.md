# SystemWallColor

*[Version française](README_FR.md)*

![Showcase](showcase.gif)

Automatic system theme synchronization with your wallpaper on **COSMIC Desktop** (Pop!_OS).

Every time you change your wallpaper or switch between light/dark mode in COSMIC, SystemWallColor:
1. Generates a matching COSMIC theme with [Matugen](https://github.com/InioX/matugen) and applies it automatically
2. Generates a terminal color palette with [Pywal](https://github.com/dylanaraps/pywal)
3. Syncs Firefox's theme with [Pywalfox](https://github.com/Frewacom/pywalfox)
4. Generates matching light/dark themes for the [Zed](https://zed.dev) editor

Everything runs in the background through a **systemd** service that watches for changes in real time.

## Requirements

- **Pop!_OS with COSMIC Desktop** (or any distribution using COSMIC)
- `sudo` access (for installing system dependencies)
- Firefox (optional, only needed if you want browser theme syncing)
- Zed (optional, only needed if you want editor theme syncing)

## Installation

```bash
git clone https://gitlab.com/Ylamm/systemwallcolor.git
cd systemwallcolor
chmod +x install.sh
./install.sh
```

The `install.sh` script takes care of:
- Installing system dependencies (`inotify-tools`, `python3-pip`, `pipx`)
- Installing Rust/Cargo if missing, then compiling `matugen`
- Installing `pywal` and `pywalfox`
- Copying the project files to `~/.local/bin/SystemWallColor/`
- Installing and enabling the user systemd service (`cosmic-watch.service`)
- Setting up the Matugen templates for COSMIC and Zed

If you use Firefox, also install the [Pywalfox](https://addons.mozilla.org/en-US/firefox/addon/pywalfox/) extension from the official store.

> ⚠️ **On first launch**, change your wallpaper once so the service detects the change and applies the initial theme.

## How it works

| Component | Role |
|---|---|
| `swcw.sh` | Watches COSMIC config files via `inotifywait` |
| `swc.py` | Runs on every detected change; orchestrates Matugen, Pywal, Pywalfox, and applies the theme |
| `cosmic-watch.service` | User systemd service that keeps `swcw.sh` running permanently |

## Zed editor theming

SystemWallColor also generates matching **Zed** themes ("Matugen Dark" / "Matugen Light") from your wallpaper colors.

On first run, `install.sh` copies the templates (`matugen/templates/zed-colors-dark.json` and `zed-colors-light.json`) and adds the `[templates.zeddark]` / `[templates.zedlight]` sections to your Matugen config. The generated theme is written directly into Zed's Flatpak sandbox config path (`~/.var/app/dev.zed.Zed/config/zed/themes/`), since Zed on Pop!_OS is typically installed via Flatpak.

To activate it in Zed:
1. Open the command palette (`ctrl-k ctrl-t`)
2. Select **Matugen Dark** or **Matugen Light**

> ⚠️ If you installed Zed a different way (native binary, apt, snap), edit the `output_path` values for `zeddark`/`zedlight` in `~/.config/matugen/config.toml` to point to `~/.config/zed/themes/` instead.

## Check that the service is running

```bash
systemctl --user status cosmic-watch.service
```

## Follow the logs live

```bash
journalctl --user -u cosmic-watch.service -f
```

## Uninstall

```bash
systemctl --user disable --now cosmic-watch.service
rm ~/.config/systemd/user/cosmic-watch.service
rm -r ~/.local/bin/SystemWallColor
```

## Known limitations

- Only works with **COSMIC Desktop** (depends on `cosmic-settings` and COSMIC-specific config files).
- Firefox syncing requires the browser to be open and the Pywalfox extension installed on the browser side.
- **cosmic-term's internal colors (background, text) currently can't be automated.** cosmic-term doesn't reload its theme even if the config file is changed in the background. To apply the new colors manually:
  1. Open cosmic-term
  2. **View → Color schemes... → Import**

     <img src="Terminal_Couleur_Aide.png" alt="Importing a theme in cosmic-term" width="30%">
  3. Select `~/.cache/wal/cosmic_term.ron`
  4. Select the "Pywal" theme from the list
- **Zed theme syncing requires Zed to be restarted** after the first generation for the new theme to appear in the theme selector. Subsequent wallpaper changes update the theme file in place without needing a restart.

## License

Personal project, free to use and modify.

## Source

The Zed matugen templates are inspired by https://github.com/InioX/matugen-themes/blob/main/templates/zed-colors.json
The Obsidian matugen template comes from https://github.com/Simorg2002/obsidian-matugen-template/tree/main
