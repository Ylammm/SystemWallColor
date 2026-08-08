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

echo "=== Installation du service systemd ==="
mkdir -p "$home/.config/systemd/user"
cp "$script_dir/cosmic-watch.service" "$home/.config/systemd/user/cosmic-watch.service"

echo "=== Activation du service ==="
systemctl --user daemon-reload
systemctl --user enable --now cosmic-watch.service

echo "=== Installation terminée ==="
echo -e "N'oubliez pas d'ajouter '$HOME/.cargo/bin' à votre PATH si ce n'est pas déjà fait.\n\033[1mVous pouvez aussi supprimer SystemWallColor.\033[0m"
systemctl --user status cosmic-watch.service --no-pager