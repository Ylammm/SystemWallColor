#!/bin/bash
set -e
home="$HOME"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


echo "=== Mise à jour ==="
sudo apt update


echo "=== Installation des paquets système ==="
sudo apt install -y python3-pip inotify-tools pipx


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
pip3 install --break-system-packages pywal


echo "=== Installation de pywalfox ==="
pipx ensurepath
export PATH="$HOME/.local/bin:$PATH"
pipx install pywalfox
pywalfox install


echo "=== Installation des fichiers du projet ==="
mkdir -p "$home/.local/bin/SystemWallColor"
cp "$script_dir/swc.py" "$home/.local/bin/SystemWallColor/swc.py"
cp "$script_dir/swcw.sh" "$home/.local/bin/SystemWallColor/swcw.sh"
chmod +x "$home/.local/bin/SystemWallColor/swc.py"
chmod +x "$home/.local/bin/SystemWallColor/swcw.sh"


echo "=== Mise en place de matugen ==="
mkdir -p "$home/.config/matugen/templates"

# Copier les templates du thème desktop et de ceux des applications, sans écraser l'existant
cp -n "$script_dir/matugen/templates/cosmic_theme_dark.txt" "$home/.config/matugen/templates/cosmic_theme_dark.txt" 2>/dev/null || true
cp -n "$script_dir/matugen/templates/cosmic_theme_light.txt" "$home/.config/matugen/templates/cosmic_theme_light.txt" 2>/dev/null || true
cp -n "$script_dir/matugen/templates/zed-colors-dark.json" "$home/.config/matugen/templates/zed-colors-dark.json" 2>/dev/null || true
cp -n "$script_dir/matugen/templates/zed-colors-light.json" "$home/.config/matugen/templates/zed-colors-light.json" 2>/dev/null || true
cp -n "$script_dir/matugen/templates/obsidian-minimal-matugen-colors.css" "$home/.config/matugen/templates/obsidian-minimal-matugen-colors.css" 2>/dev/null || true

CONFIG_FILE="$home/.config/matugen/config.toml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[config]" > "$CONFIG_FILE"
    echo "Fichier config.toml créé."
fi

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

add_template_block "cosmicdark" \
    '~/.config/matugen/templates/cosmic_theme_dark.txt' \
    '~/.config/matugen/cosmic_theme_dark.ron'

add_template_block "cosmiclight" \
    '~/.config/matugen/templates/cosmic_theme_light.txt' \
    '~/.config/matugen/cosmic_theme_light.ron'

add_template_block "zeddark" \
    '~/.config/matugen/templates/zed-colors-dark.json' \
    '~/.var/app/dev.zed.Zed/config/zed/themes/matugen_dark.json'

add_template_block "zedlight" \
    '~/.config/matugen/templates/zed-colors-light.json' \
    '~/.var/app/dev.zed.Zed/config/zed/themes/matugen_light.json'

add_template_block "obsidian" \
    '~/.config/matugen/templates/obsidian-minimal-matugen-colors.css' \
    '~/Documents/Obsidian Vault/.obsidian/snippets/Matugen.css'


echo "=== Mise en place du template Pywal pour cosmic-term ==="
mkdir -p "$home/.config/wal/templates"
cp -n "$script_dir/cosmic_term.ron" "$home/.config/wal/templates/cosmic_term.ron"


echo "=== Installation du service systemd ==="
mkdir -p "$home/.config/systemd/user"
cp "$script_dir/cosmic-watch.service" "$home/.config/systemd/user/cosmic-watch.service"


echo "=== Activation du service ==="
systemctl --user daemon-reload
systemctl --user enable cosmic-watch.service
systemctl --user restart cosmic-watch.service


echo "=== Installation terminée ==="
echo -e "N'oubliez pas d'ajouter '$HOME/.cargo/bin' à votre PATH si ce n'est pas déjà fait.\n\033[1mVous pouvez aussi supprimer SystemWallColor.\033[0m"
systemctl --user status cosmic-watch.service --no-pager
