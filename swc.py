#!/usr/bin/env python3
import os
import re
import subprocess
import json

home = os.path.expanduser("~")
MATUGEN_CONFIG = f"{home}/.config/matugen/config.toml"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(SCRIPT_DIR, "config.json")


def read_wallpaper():
    path = f"{home}/.config/cosmic/com.system76.CosmicBackground/v1/all"
    with open(path, "r") as f:
        lines = f.readlines()
    return lines[2][18:-4]


def read_mode():
    path = f"{home}/.config/cosmic/com.system76.CosmicTheme.Mode/v1/is_dark"
    with open(path, "r") as f:
        is_dark = f.readline().strip()
    return "dark" if is_dark == "true" else "light"


def _toggle_section(filepath, section_name, enable):
    """Commente ou décommente un bloc [section_name] dans un fichier TOML."""
    with open(filepath, "r") as f:
        lines = f.readlines()

    output = []
    in_section = False
    section_header = f"[{section_name}]"

    for line in lines:
        stripped = line.strip().lstrip("#").strip()
        if stripped == section_header:
            in_section = True
            output.append((section_header + "\n") if enable else ("# " + section_header + "\n"))
            continue
        if in_section:
            # fin du bloc : nouvelle section ou ligne vide
            bare = line.strip().lstrip("#").strip()
            if bare.startswith("[") or bare == "":
                in_section = False
                output.append(line)
            else:
                content = line.lstrip("#").lstrip()
                output.append(content if enable else ("# " + content))
        else:
            output.append(line)

    with open(filepath, "w") as f:
        f.writelines(output)


def enable_template(section_name):
    _toggle_section(MATUGEN_CONFIG, section_name, enable=True)


def disable_template(section_name):
    _toggle_section(MATUGEN_CONFIG, section_name, enable=False)


VALID_SCHEMES = [
    "scheme-content",
    "scheme-expressive",
    "scheme-fidelity",
    "scheme-fruit-salad",
    "scheme-monochrome",
    "scheme-neutral",
    "scheme-rainbow",
    "scheme-tonal-spot",
    "scheme-vibrant",
]

DEFAULT_SCHEME = "scheme-tonal-spot"


def get_scheme(conf):
    scheme = conf.get("matugen", {}).get("scheme", DEFAULT_SCHEME)
    if scheme not in VALID_SCHEMES:
        print(f"⚠️  Scheme '{scheme}' invalide, utilisation de '{DEFAULT_SCHEME}' par défaut.")
        return DEFAULT_SCHEME
    return scheme


def matugen(wallc, scheme):
    try:
        subprocess.run(
            [
                "matugen",
                "--source-color-index", "0",
                "--type", scheme,
                "image", wallc,
            ],
            check=True,
        )
        print("Matugen OK")
    except subprocess.CalledProcessError as e:
        print(f"Erreur Matugen : {e}")


def pywal(wallc):
    try:
        subprocess.run(["wal", "-q", "-i", wallc], check=True)
        print("Pywal OK")
    except subprocess.CalledProcessError as e:
        print(f"Erreur Pywal : {e}")


def pywalfox(modec):
    try:
        subprocess.run(["pywalfox", modec], check=True)
        subprocess.run(["pywalfox", "update"], check=True)
        print("Pywalfox OK")
    except subprocess.CalledProcessError as e:
        print(f"Erreur Pywalfox : {e}")


def cosmicsetting(modec):
    theme_file = f"{home}/.config/matugen/cosmic_theme_{modec}.ron"
    try:
        subprocess.run(
            ["cosmic-settings", "appearance", "import", theme_file], check=True
        )
        print("Theme change OK")
    except subprocess.CalledProcessError as e:
        print(f"Erreur Theme Change : {e}")


def main():
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        conf = json.load(f)

    wallc = read_wallpaper()
    modec = read_mode()
    scheme = get_scheme(conf)

    print(f"Wallpaper : {wallc}")
    print(f"System mode : {modec}")
    print(f"Scheme : {scheme}")

    if conf.get("firefox"):
        matugen(wallc, scheme)
        pywalfox(modec)

    if conf.get("zed"):
        enable_template("templates.zeddark")
        enable_template("templates.zedlight")
    else:
        disable_template("templates.zeddark")
        disable_template("templates.zedlight")

    cosmicsetting(modec)


if __name__ == "__main__":
    main()
