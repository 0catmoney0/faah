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

_faah_format_size() {
    local b=$1
    if   (( b < 1024 ));        then print -n -- "$b B"
    elif (( b < 1048576 ));     then print -n -- "$((b / 1024)) Ko"
    elif (( b < 1073741824 )); then print -n -- "$((b / 1048576)) Mo"
    else print -n -- "$((b / 1073741824)) Go"
    fi
}

_faah_get_duration() {
    command -v ffprobe >/dev/null 2>&1 || return
    local d
    d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$1" 2>/dev/null)
    [[ -z "$d" ]] && return
    local i=${d%.*}
    if (( i < 60 )); then
        print -n -- "${d:0:3}s"
    else
        printf '%dm%02ds' "$((i / 60))" "$((i % 60))"
    fi
}

_faah_file_size() {
    stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null
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
        local full="$dir/$v"
        local size dur info=""
        size=$(_faah_format_size "$(_faah_file_size "$full")" 2>/dev/null)
        dur=$(_faah_get_duration "$full")
        if [[ -n "$dur" && -n "$size" ]];   then info=" ($dur, $size)"
        elif [[ -n "$dur" ]];               then info=" ($dur)"
        elif [[ -n "$size" ]];              then info=" ($size)"
        fi
        if [[ "$v" == "$current" ]]; then
            print "  $i) $v$info  (active)"
        else
            print "  $i) $v$info"
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
