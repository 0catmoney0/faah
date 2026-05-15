# FAAH hook for zsh
# Source-d par .zshrc. Joue la video sur "command not found" (cooldown 10s).

export FAAH_DIR="${FAAH_DIR:-$HOME/.faah}"
_FAAH_LAUNCHER="$FAAH_DIR/lib/faah_launcher_unix.sh"
_FAAH_COOLDOWN_FILE="/tmp/faah_cooldown_$(id -u 2>/dev/null || echo me)"
_FAAH_COOLDOWN_SECS=10

_faah_list_videos() {
    local dir="$FAAH_DIR/media"
    [[ -d "$dir" ]] || return
    local f
    setopt local_options null_glob
    for f in "$dir"/*.mp4 "$dir"/*.mkv "$dir"/*.webm "$dir"/*.mov "$dir"/*.avi "$dir"/*.MP4 "$dir"/*.MKV; do
        print -- "${f:t}"
    done | sort -u
}

_faah_trigger() {
    local now last
    now=$(date +%s)
    if [[ -f "$_FAAH_COOLDOWN_FILE" ]]; then
        last=$(cat "$_FAAH_COOLDOWN_FILE" 2>/dev/null || echo 0)
        if (( now - last < _FAAH_COOLDOWN_SECS )); then return; fi
    fi
    print -- "$now" > "$_FAAH_COOLDOWN_FILE"
    if [[ -x "$_FAAH_LAUNCHER" ]]; then
        nohup "$_FAAH_LAUNCHER" >/dev/null 2>&1 &!
    fi
}

command_not_found_handler() {
    print -u2 -- "zsh: command not found: $1"
    _faah_trigger
    return 127
}

# Commande `faah` : interactif, affiche le dossier, liste les videos, permet de choisir la video active
faah() {
    local dir="$FAAH_DIR/media"
    local active_file="$FAAH_DIR/active"

    mkdir -p "$dir" 2>/dev/null

    local -a videos
    local v
    while IFS= read -r v; do videos+=("$v"); done < <(_faah_list_videos)

    print "\nDossier video : $dir"

    if (( ${#videos[@]} == 0 )); then
        print "Aucune video pour le moment."
        print "Pose un fichier .mp4 / .mkv / .webm dans le dossier ci-dessus, puis retape \"faah\".\n"
        return
    fi

    local current=""
    [[ -f "$active_file" ]] && current=$(cat "$active_file" 2>/dev/null)
    [[ -n "$current" && ! -f "$dir/$current" ]] && current=""
    [[ -z "$current" ]] && current="${videos[1]}"

    print "\nVideos disponibles :"
    local i=1
    for v in $videos; do
        if [[ "$v" == "$current" ]]; then
            print "  $i) $v  (active)"
        else
            print "  $i) $v"
        fi
        ((i++))
    done

    if (( ${#videos[@]} == 1 )); then
        print -- "$current" > "$active_file"
        print "\n[OK] Une seule video : elle est active.\n"
        return
    fi

    printf '\nChoisis une video (1-%d, Entree pour garder "%s") : ' "${#videos[@]}" "$current"
    local choice
    read -r choice
    if [[ -z "$choice" ]]; then
        print -- "$current" > "$active_file"
        print "(inchange)\n"
        return
    fi
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#videos[@]} )); then
        print "Choix invalide.\n"
        return 1
    fi
    local selected="${videos[$choice]}"
    print -- "$selected" > "$active_file"
    print "[OK] Video active : $selected\n"
}
