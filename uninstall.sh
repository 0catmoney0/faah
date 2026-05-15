#!/usr/bin/env bash
# Desinstalleur FAAH pour macOS et Linux.
set -e

FAAH_DIR="$HOME/.faah"
MARKER="# === FAAH hook ==="

echo "[*] Desinstallation de FAAH"

# Supprime le hook des rcfiles
for RCFILE in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc"; do
    [[ -f "$RCFILE" ]] || continue
    if grep -qF "$MARKER" "$RCFILE"; then
        # Supprime la ligne marker + la suivante
        awk -v marker="$MARKER" '
            $0 == marker { skip=2; next }
            skip > 0     { skip--; next }
            { print }
        ' "$RCFILE" > "$RCFILE.faah_tmp" && mv "$RCFILE.faah_tmp" "$RCFILE"
        echo "[-] Hook retire de $RCFILE"
    fi
done

# Supprime le dossier (mais on garde media/ pour pas perdre la video)
if [[ -d "$FAAH_DIR" ]]; then
    read -r -p "Supprimer aussi le dossier $FAAH_DIR (avec ta video) ? [y/N] " ans
    case "$ans" in
        y|Y|yes|Yes)
            rm -rf "$FAAH_DIR"
            echo "[-] $FAAH_DIR supprime"
            ;;
        *)
            rm -rf "$FAAH_DIR/lib"
            echo "[-] $FAAH_DIR/lib supprime (media/ conserve)"
            ;;
    esac
fi

# Nettoie les fichiers temp
rm -f "/tmp/faah_$(id -u 2>/dev/null || echo me).lock" \
      "/tmp/faah_cooldown_$(id -u 2>/dev/null || echo me)"

echo "[OK] Desinstalle. Ouvre un nouveau terminal pour confirmer."
