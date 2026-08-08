#!/bin/bash
set -e
home="$HOME"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === Détection de la distribution ===
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

case "$DISTRO" in
    ubuntu|pop|debian|linuxmint)
        PKG_MANAGER="apt"
        ;;
    arch|endeavouros|manjaro|cachyos)
        PKG_MANAGER="pacman"
        ;;
    fedora)
        PKG_MANAGER="dnf"
        ;;
    *)
        echo "⚠️  Distribution non reconnue ($DISTRO)."
        echo "Ce script supporte : Ubuntu/Pop!_OS/Debian, Arch/EndeavourOS/Manjaro, Fedora."
        exit 1
        ;;
esac

echo "Distribution détectée : $DISTRO (gestionnaire : $PKG_MANAGER)"

install_system_packages() {
    echo "=== Mise à jour et installation des paquets système ==="
    case "$PKG_MANAGER" in
        apt)
            sudo apt update
            sudo apt install -y python3-pip inotify-tools pipx
            ;;
        pacman)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --needed --noconfirm python-pip inotify-tools python-pipx
            ;;
        dnf)
            sudo dnf check-update || true
            sudo dnf install -y python3-pip inotify-tools pipx
            ;;
    esac
}

# === Valeurs par défaut ===
DO_FIREFOX=false
DO_ZED=false
DO_OBSIDIAN=false
DO_ALL=false

if [ $# -eq 0 ]; then
    DO_ALL=true
fi

for arg in "$@"; do
    case $arg in
        --firefox)   DO_FIREFOX=true ;;
        --zed)       DO_ZED=true ;;
        --obsidian)  DO_OBSIDIAN=true ;;
        --all)       DO_ALL=true ;;
        -h|--help)
            echo "Usage: ./install.sh [options]"
            echo ""
            echo "Sans option : installe/active uniquement le cœur (COSMIC + Pywal)."
            echo "Les composants non listés dans les flags sont désactivés (leurs"
            echo "sections Matugen sont retirées de la config s'ils étaient actifs)."
            echo ""
            echo "Options:"
            echo "  --firefox    Active la synchronisation du thème Firefox (Pywalfox)"
            echo "  --zed        Active la synchronisation du thème Zed"
            echo "  --obsidian   Active la synchronisation du thème Obsidian"
            echo "  --all        Active tout"
            exit 0
            ;;
        *)
            echo "Option inconnue : $arg (utilisez --help)"
            exit 1
            ;;
    esac
done

if [ "$DO_ALL" = true ]; then
    DO_FIREFOX=true
    DO_ZED=true
    DO_OBSIDIAN=true
fi

echo "=== Composants sélectionnés ==="
echo "Cœur (COSMIC + Pywal) : toujours actif"
echo "Firefox (Pywalfox)    : $DO_FIREFOX"
echo "Zed                   : $DO_ZED"
echo "Obsidian              : $DO_OBSIDIAN"
echo ""

install_core_system() {
    install_system_packages

    echo "=== Installation de Rust et Cargo ==="
    if ! command -v cargo &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        echo "Cargo déjà installé."
    fi

    echo "=== Installation de matugen ==="
    cargo install matugen

    echo "=== Installation de pywal ==="
    if [ "$PKG_MANAGER" = "pacman" ]; then
        pip3 install --break-system-packages pywal 2>/dev/null || pip3 install --user pywal
    else
        pip3 install --break-system-packages pywal
    fi
}

install_firefox() {
    echo "=== Installation de pywalfox ==="
    pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"
    pipx install pywalfox
    pywalfox install
}

install_project_files() {
    echo "=== Installation des fichiers du projet ==="
    mkdir -p "$home/.local/bin/SystemWallColor"
    cp "$script_dir/swc.py" "$home/.local/bin/SystemWallColor/swc.py"
    cp "$script_dir/swcw.sh" "$home/.local/bin/SystemWallColor/swcw.sh"
    chmod +x "$home/.local/bin/SystemWallColor/swc.py"
    chmod +x "$home/.local/bin/SystemWallColor/swcw.sh"
    chmod +x "$home/.local/bin/SystemWallColor/uninstall.sh"
}

add_template_block() {
    local name="$1"
    local input_path="$2"
    local output_path="$3"

    if ! grep -q "\[templates\.$name\]" "$CONFIG_FILE"; then
        {
            echo ""
            echo "[templates.$name]"
            echo "input_path = '$input_path'"
            echo "output_path = '$output_path'"
        } >> "$CONFIG_FILE"
        echo "Section [templates.$name] ajoutée."
    else
        echo "Section [templates.$name] déjà présente, non modifiée."
    fi
}

# Retire une section [templates.NAME] (header + les 2 lignes input_path/output_path
# qui suivent) si elle existe. Structure fixe présumée : 3 lignes par bloc.
remove_template_block() {
    local name="$1"

    if [ ! -f "$CONFIG_FILE" ]; then
        return
    fi

    if grep -q "^\[templates\.$name\]$" "$CONFIG_FILE"; then
        sed -i "/^\[templates\.$name\]$/,+2d" "$CONFIG_FILE"
        # Nettoie une éventuelle ligne vide devenue orpheline juste avant
        sed -i '/./,/^$/!d' "$CONFIG_FILE" 2>/dev/null || true
        echo "Section [templates.$name] retirée (composant désactivé)."
    fi
}

setup_matugen_core() {
    echo "=== Mise en place de matugen (thème COSMIC) ==="
    mkdir -p "$home/.config/matugen/templates"

    cp -n "$script_dir/matugen/templates/cosmic_theme_dark.txt" "$home/.config/matugen/templates/cosmic_theme_dark.txt" 2>/dev/null || true
    cp -n "$script_dir/matugen/templates/cosmic_theme_light.txt" "$home/.config/matugen/templates/cosmic_theme_light.txt" 2>/dev/null || true

    CONFIG_FILE="$home/.config/matugen/config.toml"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "[config]" > "$CONFIG_FILE"
        echo "Fichier config.toml créé."
    fi

    add_template_block "cosmicdark" \
        '~/.config/matugen/templates/cosmic_theme_dark.txt' \
        '~/.config/matugen/cosmic_theme_dark.ron'

    add_template_block "cosmiclight" \
        '~/.config/matugen/templates/cosmic_theme_light.txt' \
        '~/.config/matugen/cosmic_theme_light.ron'
}

setup_matugen_zed() {
    echo "=== Mise en place de matugen (thème Zed) ==="
    cp -n "$script_dir/matugen/templates/zed-colors-dark.json" "$home/.config/matugen/templates/zed-colors-dark.json" 2>/dev/null || true
    cp -n "$script_dir/matugen/templates/zed-colors-light.json" "$home/.config/matugen/templates/zed-colors-light.json" 2>/dev/null || true

    add_template_block "zeddark" \
        '~/.config/matugen/templates/zed-colors-dark.json' \
        '~/.var/app/dev.zed.Zed/config/zed/themes/matugen_dark.json'

    add_template_block "zedlight" \
        '~/.config/matugen/templates/zed-colors-light.json' \
        '~/.var/app/dev.zed.Zed/config/zed/themes/matugen_light.json'
}

disable_matugen_zed() {
    remove_template_block "zeddark"
    remove_template_block "zedlight"
}

setup_matugen_obsidian() {
    echo "=== Mise en place de matugen (thème Obsidian) ==="
    cp -n "$script_dir/matugen/templates/obsidian-minimal-matugen-colors.css" "$home/.config/matugen/templates/obsidian-minimal-matugen-colors.css" 2>/dev/null || true

    add_template_block "obsidian" \
        '~/.config/matugen/templates/obsidian-minimal-matugen-colors.css' \
        '~/Documents/Obsidian Vault/.obsidian/snippets/Matugen.css'
}

disable_matugen_obsidian() {
    remove_template_block "obsidian"
}

setup_pywal_cosmic_term() {
    echo "=== Mise en place du template Pywal pour cosmic-term ==="
    mkdir -p "$home/.config/wal/templates"
    cp -n "$script_dir/cosmic_term.ron" "$home/.config/wal/templates/cosmic_term.ron"
}

setup_systemd_service() {
    echo "=== Installation du service systemd ==="
    mkdir -p "$home/.config/systemd/user"
    cp "$script_dir/cosmic-watch.service" "$home/.config/systemd/user/cosmic-watch.service"

    echo "=== Activation du service ==="
    systemctl --user daemon-reload
    systemctl --user enable cosmic-watch.service
    systemctl --user restart cosmic-watch.service
}

# === Exécution ===

install_core_system
[ "$DO_FIREFOX" = true ] && install_firefox

install_project_files

setup_matugen_core

if [ "$DO_ZED" = true ]; then
    setup_matugen_zed
else
    disable_matugen_zed
fi

if [ "$DO_OBSIDIAN" = true ]; then
    setup_matugen_obsidian
else
    disable_matugen_obsidian
fi

setup_pywal_cosmic_term
setup_systemd_service

echo "=== Installation terminée ==="
echo -e "N'oubliez pas d'ajouter '$HOME/.cargo/bin' à votre PATH si ce n'est pas déjà fait.\n\033[1mVous pouvez aussi supprimer SystemWallColor.\033[0m"
systemctl --user status cosmic-watch.service --no-pager
