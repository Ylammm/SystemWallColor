# SystemWallColor

*[Version française](README_FR.md)*

![Showcase](showcase.gif)

Automatic system theme synchronization with your wallpaper on **COSMIC Desktop** (Pop!_OS).

Every time you change your wallpaper or switch between light/dark mode in COSMIC, SystemWallColor:
1. Generates a matching COSMIC theme with [Matugen](https://github.com/InioX/matugen) and applies it automatically
2. Generates a terminal color palette with [Pywal](https://github.com/dylanaraps/pywal)
3. Optionally syncs Firefox's theme with [Pywalfox](https://github.com/Frewacom/pywalfox)
4. Optionally generates matching light/dark themes for the [Zed](https://zed.dev) editor
5. Optionally generates a matching CSS snippet for [Obsidian](https://obsidian.md)

Everything runs in the background through a **systemd** service that watches for changes in real time.

## Requirements

- **Pop!_OS with COSMIC Desktop**, or **Arch/EndeavourOS/Manjaro/CachyOS**, or **Fedora** running COSMIC Desktop
- `sudo` access (for installing system dependencies)
- Firefox (optional, only needed if you want browser theme syncing)
- Zed (optional, only needed if you want editor theme syncing)
- Obsidian (optional, only needed if you want notes app theme syncing)

## Installation

```bash
git clone https://gitlab.com/Ylamm/systemwallcolor.git
cd systemwallcolor
chmod +x install.sh
./install.sh [options]
```

`install.sh` auto-detects your distribution (Ubuntu/Pop!_OS/Debian → `apt`, Arch-based → `pacman`, Fedora → `dnf`) and installs the right system packages accordingly.

The installed packages are Cargo, Pywal, Pywalfox, and Matugen. If you run into issues, you can install them manually.

**The core (COSMIC theme + Pywal terminal palette) is always installed.** App integrations (Firefox, Zed, Obsidian) are opt-in, either via flags at install time, or by editing the `config.json` file afterwards:

| Flag | Effect |
|---|---|
| *(none)* | Core only |
| `--firefox` | Also enables Firefox theme sync (Pywalfox) |
| `--zed` | Also enables Zed editor theme sync |
| `--obsidian` | Also enables Obsidian theme sync |
| `--all` | Enables everything |
| `--help` | Shows usage |

Flags can be combined, e.g. `./install.sh --firefox --zed`.

> **Re-running `install.sh` updates the active configuration to match the flags you pass.** If a component was previously enabled and you run the script again without its flag, its Matugen template section is automatically removed from `~/.config/matugen/config.toml` — so it stops being generated.

If you enable Firefox syncing, also install the [Pywalfox](https://addons.mozilla.org/en-US/firefox/addon/pywalfox/) extension from the official store.

> ⚠️ **On first launch**, change your wallpaper once so the service detects the change and applies the initial theme.

## How it works

| Component | Role |
|---|---|
| `swcw.sh` | Watches COSMIC config files via `inotifywait` |
| `swc.py` | Runs on every detected change; orchestrates Matugen, Pywal, Pywalfox, and applies the theme |
| `cosmic-watch.service` | User systemd service that keeps `swcw.sh` running permanently |

## Editing the configuration without reinstalling

The `~/.local/bin/SystemWallColor/config.json` file controls which applications are synced (`firefox`, `zed`, `obsidian`) as well as Matugen's settings (`source-color-index`, `scheme`). You can edit it directly — changes take effect the next time the service triggers, no need to re-run `install.sh`.

> ⚠️ Note that re-running `install.sh` fully regenerates this file from the flags you pass, overwriting any manual changes.

### Zed editor theming

*(enabled with `--zed` or `--all`)*

SystemWallColor generates matching **Zed** themes ("Matugen Dark" / "Matugen Light") from your wallpaper colors.

The templates (`matugen/templates/zed-colors-dark.json` and `zed-colors-light.json`) are copied and the `[templates.zeddark]` / `[templates.zedlight]` sections are added to your Matugen config. The generated theme is written directly into Zed's Flatpak sandbox config path (`~/.var/app/dev.zed.Zed/config/zed/themes/`), since Zed on Pop!_OS is typically installed via Flatpak.

To activate it in Zed:
1. Open the command palette (`ctrl-k ctrl-t`)
2. Select **Matugen Dark** or **Matugen Light**

> ⚠️ If you installed Zed a different way (native binary, apt, snap), edit the `output_path` values for `zeddark`/`zedlight` in `~/.config/matugen/config.toml` to point to `~/.config/zed/themes/` instead.

### Obsidian theming

*(enabled with `--obsidian` or `--all`)*

SystemWallColor generates a matching CSS snippet for **Obsidian**, with separate light and dark variants, using the `[templates.obsidian]` section in your Matugen config.

> ⚠️ **The output path is hardcoded to a specific vault** (`~/Documents/Obsidian Vault/.obsidian/snippets/Matugen.css` by default). Edit the `output_path` in `~/.config/matugen/config.toml` to match your own vault's location before it will work.

To activate it in Obsidian:
1. Open **Settings → Appearance → CSS snippets**
2. Enable the **Matugen** snippet

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
chmod +x uninstall.sh
./uninstall.sh
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
- **Obsidian's vault path is hardcoded** in `matugen/config.toml` and must be edited manually to match your own vault before the snippet will be generated in the right place.
- **Arch/Fedora support is untested** — the package names used for `pacman`/`dnf` are best-effort and may need adjusting.

## Source

- The Zed matugen templates are inspired by https://github.com/InioX/matugen-themes/blob/main/templates/zed-colors.json
- The Obsidian matugen template comes from https://github.com/Simorg2002/obsidian-matugen-template/tree/main

# Upcoming
- [x] Add the choice of Matugen's mode/backend.
- [ ] Auto-detect whether apps (Zed, Obsidian, etc.) are installed via Flatpak or natively, and adjust Matugen output paths (`output_path`) accordingly.
- [ ] Implement manual wallpaper selection ("Follow COSMIC" vs "Custom image").
- [ ] Add saturation and lightness settings for Matugen.
- [ ] Add toggles for other synced applications (Alacritty, Discord, etc.).
- [ ] Allow custom path configuration (Obsidian / Zed).
- [ ] Add a debounce delay for the inotify watcher.
- [ ] Integrate desktop notifications (notify-send).
- [ ] Add a custom command system (post-generation hooks).
