#!/usr/bin/env python3
import os
import subprocess

home = os.path.expanduser("~")

wall = open(f"{home}/.config/cosmic/com.system76.CosmicBackground/v1/all", 'r')
wallc = wall.readlines()[2]
print(f"Wallpaper : {wallc[18:-4]}")

mode = open(f"{home}/.config/cosmic/com.system76.CosmicTheme.Mode/v1/is_dark", 'r')
modec = mode.readline().strip()
if modec == 'true':
    modec = "dark"
else:
    modec = "light"
print(f"System mode : {modec}")

try:
    subprocess.run(["matugen", "--source-color-index", "0", "image", wallc[18:-4]], check=True)
    print("Matugen OK")
except subprocess.CalledProcessError as e:
    print(f"Erreur Matugen : {e}")
    
try:
    subprocess.run(["wal", "-q", "-i", wallc[18:-4]], check=True)
    print("Pywal OK")
except subprocess.CalledProcessError as e:
    print(f"Erreur Pywal : {e}")

try:
    subprocess.run(["pywalfox", modec], check=True)
    subprocess.run(["pywalfox", "update"], check=True)
    print("Pywalfox OK")
except subprocess.CalledProcessError as e:
    print(f"Erreur Pywalfox : {e}")

theme_file = f"{home}/.config/matugen/cosmic_theme_{modec}.ron"
try:
    subprocess.run(["cosmic-settings", "appearance", "import", theme_file], check=True)
    print("Theme change OK")
except subprocess.CalledProcessError as e:
    print(f"Erreur Theme Change : {e}")

wall.close()
mode.close()