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

# Met en pause les autres medias (Spotify, YouTube, etc.) avant de jouer
pause_other_media() {
    # Linux : playerctl pause tout ce qui supporte MPRIS (Spotify, Firefox, Chrome, VLC, mpv...)
    if command -v playerctl >/dev/null 2>&1; then
        playerctl pause >/dev/null 2>&1 || true
    fi
    # macOS : pause les apps connues si elles tournent
    if command -v osascript >/dev/null 2>&1; then
        osascript -e 'tell application "Spotify" to if it is running then pause' >/dev/null 2>&1 || true
        osascript -e 'tell application "Music" to if it is running then pause'   >/dev/null 2>&1 || true
        osascript -e 'tell application "VLC" to if it is running then pause'     >/dev/null 2>&1 || true
    fi
}
pause_other_media

# Plein ecran, son de la video, ferme a la fin, silencieux
ffplay -fs -autoexit -loglevel quiet -window_title "FAAH" "$VIDEO" </dev/null >/dev/null 2>&1
