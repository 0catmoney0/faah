# FAAH hook for zsh
# Source-d par .zshrc. Joue la video sur "command not found" (cooldown 10s).

export FAAH_DIR="${FAAH_DIR:-$HOME/.faah}"
_FAAH_LAUNCHER="$FAAH_DIR/lib/faah_launcher_unix.sh"
_FAAH_COOLDOWN_FILE="/tmp/faah_cooldown_$(id -u 2>/dev/null || echo me)"
_FAAH_COOLDOWN_SECS=10

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

# Commande `faah` : affiche ou mettre ta video
faah() {
    local dir="${FAAH_DIR:-$HOME/.faah}/media"
    print ""
    print "Pose ton fichier video ici :"
    print "    $dir/video.mp4"
    print ""
    print "(extension libre : .mp4 .mkv .webm... le son doit etre dans la video)"
    local existing
    existing=$(ls "$dir"/video.* 2>/dev/null | head -n 1)
    if [[ -n "$existing" ]]; then
        print "Video actuelle : $existing"
    else
        print "Aucune video posee pour le moment."
    fi
    print ""
}
