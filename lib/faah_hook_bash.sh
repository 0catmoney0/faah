# FAAH hook for bash
# Source-d par .bashrc. Joue la video sur "command not found" (cooldown 10s).

export FAAH_DIR="${FAAH_DIR:-$HOME/.faah}"
_FAAH_LAUNCHER="$FAAH_DIR/lib/faah_launcher_unix.sh"
_FAAH_COOLDOWN_FILE="/tmp/faah_cooldown_$(id -u 2>/dev/null || echo me)"
_FAAH_COOLDOWN_SECS=10

_faah_list_videos() {
    local dir="$FAAH_DIR/media"
    [[ -d "$dir" ]] || return
    local f
    local _saved
    _saved=$(shopt -p nullglob 2>/dev/null || true)
    shopt -s nullglob 2>/dev/null || true
    for f in "$dir"/*.mp4 "$dir"/*.mkv "$dir"/*.webm "$dir"/*.mov "$dir"/*.avi "$dir"/*.MP4 "$dir"/*.MKV; do
        [[ -f "$f" ]] && printf '%s\n' "$(basename "$f")"
    done | sort -u
    [[ -n "$_saved" ]] && eval "$_saved" 2>/dev/null || true
}

_faah_trigger() {
    local now last
    now=$(date +%s)
    if [[ -f "$_FAAH_COOLDOWN_FILE" ]]; then
        last=$(cat "$_FAAH_COOLDOWN_FILE" 2>/dev/null || echo 0)
        if (( now - last < _FAAH_COOLDOWN_SECS )); then return; fi
    fi
    echo "$now" > "$_FAAH_COOLDOWN_FILE"
    if [[ -x "$_FAAH_LAUNCHER" ]]; then
        nohup "$_FAAH_LAUNCHER" >/dev/null 2>&1 &
        disown 2>/dev/null || true
    fi
}

command_not_found_handle() {
    printf 'bash: %s: command not found\n' "$1" >&2
    _faah_trigger
    return 127
}

# Commande `faah` : interactif, affiche le dossier, liste les videos, permet de choisir la video active
faah() {
    local dir="$FAAH_DIR/media"
    local active_file="$FAAH_DIR/active"

    mkdir -p "$dir" 2>/dev/null

    local videos=()
    local v
    while IFS= read -r v; do videos+=("$v"); done < <(_faah_list_videos)

    printf '\nDossier video : %s\n' "$dir"

    if [[ ${#videos[@]} -eq 0 ]]; then
        printf 'Aucune video pour le moment.\n'
        printf 'Pose un fichier .mp4 / .mkv / .webm dans le dossier ci-dessus, puis retape "faah".\n\n'
        return
    fi

    local current=""
    [[ -f "$active_file" ]] && current=$(cat "$active_file" 2>/dev/null)
    # Si le fichier actif n'existe plus, on l'oublie
    [[ -n "$current" && ! -f "$dir/$current" ]] && current=""
    # Si rien d'actif, on prend la premiere par defaut
    [[ -z "$current" ]] && current="${videos[0]}"

    printf '\nVideos disponibles :\n'
    local i=1
    for v in "${videos[@]}"; do
        if [[ "$v" == "$current" ]]; then
            printf '  %d) %s  (active)\n' "$i" "$v"
        else
            printf '  %d) %s\n' "$i" "$v"
        fi
        ((i++))
    done

    if [[ ${#videos[@]} -eq 1 ]]; then
        echo "$current" > "$active_file"
        printf '\n[OK] Une seule video : elle est active.\n\n'
        return
    fi

    printf '\nChoisis une video (1-%d, Entree pour garder "%s") : ' "${#videos[@]}" "$current"
    local choice
    read -r choice
    if [[ -z "$choice" ]]; then
        echo "$current" > "$active_file"
        printf '(inchange)\n\n'
        return
    fi
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#videos[@]} )); then
        printf 'Choix invalide.\n\n'
        return 1
    fi
    local selected="${videos[$((choice-1))]}"
    echo "$selected" > "$active_file"
    printf '[OK] Video active : %s\n\n' "$selected"
}
