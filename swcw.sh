#!/bin/bash
home="$HOME"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
wall_dir="$home/.config/cosmic/com.system76.CosmicBackground/v1"
mode_dir="$home/.config/cosmic/com.system76.CosmicTheme.Mode/v1"

inotifywait -m -e close_write,create,moved_to \
  "$wall_dir" "$mode_dir" |
while read -r dir event file; do
  case "$file" in
    all|is_dark)
      echo "$(date): $file modifié ($event) — lancement de l'exécutable"
      "$script_dir/swc.py"
      ;;
  esac
done