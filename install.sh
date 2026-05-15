#!/usr/bin/env bash
# Installeur FAAH pour macOS et Linux (bash et zsh).
# Usage : curl -fsSL https://raw.githubusercontent.com/0catmoney0/faah/main/install.sh | bash
set -e

FAAH_DIR="$HOME/.faah"
RAW="https://raw.githubusercontent.com/0catmoney0/faah/main"

echo "[*] Installation de FAAH dans $FAAH_DIR"

mkdir -p "$FAAH_DIR/media"
mkdir -p "$FAAH_DIR/lib"

# Fetch des fichiers lib depuis le repo
fetch() {
    local url="$1" dst="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dst"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$dst" "$url"
    else
        echo "[!] Ni curl ni wget disponibles. Installe l'un des deux." >&2
        exit 1
    fi
}

fetch "$RAW/lib/faah_hook_bash.sh"     "$FAAH_DIR/lib/faah_hook_bash.sh"
fetch "$RAW/lib/faah_hook_zsh.sh"      "$FAAH_DIR/lib/faah_hook_zsh.sh"
fetch "$RAW/lib/faah_launcher_unix.sh" "$FAAH_DIR/lib/faah_launcher_unix.sh"
chmod +x "$FAAH_DIR/lib/faah_launcher_unix.sh"

# Detecte le shell de connexion
SHELL_NAME="$(basename "${SHELL:-/bin/bash}")"
case "$SHELL_NAME" in
    bash)
        RCFILE="$HOME/.bashrc"
        [[ "$(uname)" == "Darwin" && -f "$HOME/.bash_profile" ]] && RCFILE="$HOME/.bash_profile"
        HOOK_FILE="$FAAH_DIR/lib/faah_hook_bash.sh"
        ;;
    zsh)
        RCFILE="$HOME/.zshrc"
        HOOK_FILE="$FAAH_DIR/lib/faah_hook_zsh.sh"
        ;;
    *)
        echo "[!] Shell non supporte : $SHELL_NAME (seuls bash et zsh sont geres)"
        exit 1
        ;;
esac

MARKER="# === FAAH hook ==="
LINE="$MARKER"$'\n'"[ -f \"$HOOK_FILE\" ] && source \"$HOOK_FILE\""

if grep -qF "$MARKER" "$RCFILE" 2>/dev/null; then
    echo "[=] Hook deja present dans $RCFILE"
else
    printf '\n%s\n' "$LINE" >> "$RCFILE"
    echo "[+] Hook ajoute a $RCFILE"
fi

# Verifie ffplay
if ! command -v ffplay >/dev/null 2>&1; then
    echo ""
    echo "[!] ffplay (ffmpeg) introuvable. Installe-le :"
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "    brew install ffmpeg"
    elif command -v apt >/dev/null 2>&1; then
        echo "    sudo apt install ffmpeg"
    elif command -v dnf >/dev/null 2>&1; then
        echo "    sudo dnf install ffmpeg"
    elif command -v pacman >/dev/null 2>&1; then
        echo "    sudo pacman -S ffmpeg"
    else
        echo "    (installe ffmpeg via ton gestionnaire de paquets)"
    fi
fi

echo ""
echo "[OK] Installation terminee."
echo "    1. Pose ta video dans : $FAAH_DIR/media/video.mp4 (extension libre)"
echo "    2. Recharge ton shell : source $RCFILE  (ou ouvre un nouveau terminal)"
echo "    3. Tape une commande inconnue (ex: blabla) pour declencher."
