#!/usr/bin/env bash
# Joue la video FAAH en plein ecran sur TOUS les ecrans detectes
set -u

FAAH_DIR="${FAAH_DIR:-$HOME/.faah}"
LOCKFILE="/tmp/faah_$(id -u 2>/dev/null || echo me).lock"

# Single instance via flock (si dispo)
exec 200>"$LOCKFILE"
if command -v flock >/dev/null 2>&1; then
    flock -n 200 || exit 0
fi

# Selection de la video active : 1) fichier 'active' valide, 2) 1ere video trouvee
VIDEO=""
ACTIVE_FILE="$FAAH_DIR/active"
if [[ -f "$ACTIVE_FILE" ]]; then
    active_name=$(tr -d '\r\n' < "$ACTIVE_FILE" 2>/dev/null)
    if [[ -n "$active_name" && -f "$FAAH_DIR/media/$active_name" ]]; then
        VIDEO="$FAAH_DIR/media/$active_name"
    fi
fi
if [[ -z "$VIDEO" ]]; then
    shopt -s nullglob 2>/dev/null || true
    for f in "$FAAH_DIR/media/"*.mp4 "$FAAH_DIR/media/"*.mkv "$FAAH_DIR/media/"*.webm "$FAAH_DIR/media/"*.mov "$FAAH_DIR/media/"*.avi; do
        [[ -f "$f" ]] && VIDEO="$f" && break
    done
fi
[[ -z "$VIDEO" || ! -f "$VIDEO" ]] && exit 0

# ffplay obligatoire
command -v ffplay >/dev/null 2>&1 || exit 0

# Pause les autres medias (Spotify, YouTube, VLC...) avant de jouer
pause_other_media() {
    if command -v playerctl >/dev/null 2>&1; then
        playerctl pause >/dev/null 2>&1 || true
    fi
    if command -v osascript >/dev/null 2>&1; then
        osascript -e 'tell application "Spotify" to if it is running then pause' >/dev/null 2>&1 || true
        osascript -e 'tell application "Music" to if it is running then pause'   >/dev/null 2>&1 || true
        osascript -e 'tell application "VLC" to if it is running then pause'     >/dev/null 2>&1 || true
    fi
}
pause_other_media

# Detection des ecrans : retourne lignes "X Y WIDTH HEIGHT"
detect_screens() {
    # Override : si FAAH_NO_MULTI_SCREEN est defini, on saute la detection
    [[ -n "${FAAH_NO_MULTI_SCREEN:-}" ]] && return

    local os
    os="$(uname)"

    # Linux X11 : xrandr donne positions et tailles absolues
    if [[ "$os" == "Linux" ]] && command -v xrandr >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
        xrandr --listmonitors 2>/dev/null | tail -n +2 | while IFS= read -r line; do
            if [[ "$line" =~ ([0-9]+)/[0-9]+x([0-9]+)/[0-9]+\+([0-9]+)\+([0-9]+) ]]; then
                printf '%s %s %s %s\n' "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
            fi
        done
        return
    fi

    # macOS : system_profiler donne les resolutions. On suppose un alignement horizontal.
    if [[ "$os" == "Darwin" ]] && command -v system_profiler >/dev/null 2>&1; then
        local x_off=0 w h line
        while IFS= read -r line; do
            if [[ "$line" =~ Resolution:.*\ ([0-9]+)\ x\ ([0-9]+) ]]; then
                w="${BASH_REMATCH[1]}"
                h="${BASH_REMATCH[2]}"
                printf '%d %d %d %d\n' "$x_off" 0 "$w" "$h"
                x_off=$((x_off + w))
            fi
        done < <(system_profiler SPDisplaysDataType 2>/dev/null)
        return
    fi
}

# Lit la liste des ecrans
SCREENS=()
while IFS= read -r s; do
    [[ -n "$s" ]] && SCREENS+=("$s")
done < <(detect_screens)

if [[ ${#SCREENS[@]} -gt 1 ]]; then
    # Multi-ecrans : une instance ffplay par moniteur, seul le 1er a le son
    pids=()
    i=0
    for screen in "${SCREENS[@]}"; do
        # shellcheck disable=SC2086
        read -r sx sy sw sh <<< "$screen"
        if (( i == 0 )); then
            audio_arg=""
        else
            audio_arg="-an"
        fi
        ffplay -noborder -alwaysontop \
               -left "$sx" -top "$sy" -x "$sw" -y "$sh" \
               -autoexit -loglevel quiet $audio_arg \
               "$VIDEO" </dev/null >/dev/null 2>&1 &
        pids+=($!)
        ((i++))
    done
    # Attend la fin de l'instance principale (1er ecran), puis tue les autres
    wait "${pids[0]}" 2>/dev/null || true
    for pid in "${pids[@]:1}"; do
        kill "$pid" 2>/dev/null || true
    done
else
    # 1 seul ecran detecte (ou detection echouee) : fullscreen classique
    ffplay -fs -autoexit -loglevel quiet "$VIDEO" </dev/null >/dev/null 2>&1
fi
