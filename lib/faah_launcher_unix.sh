#!/usr/bin/env bash
# Joue la video FAAH en plein ecran via ffplay (single instance + cooldown geres par le hook)
set -u

FAAH_DIR="${FAAH_DIR:-$HOME/.faah}"
LOCKFILE="/tmp/faah_$(id -u 2>/dev/null || echo me).lock"

# Single instance (flock)
exec 200>"$LOCKFILE"
if ! command -v flock >/dev/null 2>&1; then
    : # pas de flock dispo (mac) -> on continue, le cooldown cote hook protege
elif ! flock -n 200; then
    exit 0
fi

# Cherche la video
shopt -s nullglob 2>/dev/null || true
VIDEOS=("$FAAH_DIR/media/"video.*)
if [[ ${#VIDEOS[@]} -eq 0 || ! -f "${VIDEOS[0]}" ]]; then
    exit 0
fi
VIDEO="${VIDEOS[0]}"

# ffplay obligatoire
if ! command -v ffplay >/dev/null 2>&1; then
    exit 0
fi

# Plein ecran, son de la video, ferme a la fin, silencieux
ffplay -fs -autoexit -loglevel quiet -window_title "FAAH" "$VIDEO" </dev/null >/dev/null 2>&1
