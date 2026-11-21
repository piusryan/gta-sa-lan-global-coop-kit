#!/usr/bin/env bash
# Native Linux (Arch) replacement for Switch-Network-Mode.bat / .ps1
# Edits coop/server.ini for LAN or Global (internet) story co-op and can launch the game.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$ROOT/coop/server.ini"
BACKUP="$ROOT/coop/server.ini.bak"
STARTER="$ROOT/start-story-coop.sh"

# ---------- config helpers ----------

# Print the value of a key from an INI file (first match, comments ignored).
get_setting() {
    local file="$1" key="$2" line
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ "$line" =~ ^[[:space:]]*\; ]]; then
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*"$key"[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            local value="${BASH_REMATCH[1]}"
            value="${value%"${value##*[![:space:]]}"}"  # trim trailing whitespace
            printf '%s' "$value"
            return 0
        fi
    done < "$file"
    return 1
}

# Replace (or append) a key in an INI file, keeping the file's CRLF/LF style
# and all comments/other keys untouched.
set_setting() {
    local file="$1" key="$2" value="$3"
    local tmp="${file}.switch-tmp.$$"
    local line crlf=0 found=0

    [[ -s "$file" ]] && [[ "$(head -c 200 "$file" | tr -d '\n' | grep -c $'\r')" -gt 0 ]] && crlf=1

    : > "$tmp"
    while IFS= read -r line || [[ -n "$line" ]]; do
        local had_cr=0 ending=$'\n'
        [[ "$line" == *$'\r' ]] && { had_cr=1; line="${line%$'\r'}"; }
        (( had_cr )) && ending=$'\r\n'

        if (( ! found )) && [[ ! "$line" =~ ^[[:space:]]*[#\;] ]] \
           && [[ "$line" =~ ^[[:space:]]*"$key"[[:space:]]*= ]]; then
            local prefix="${line%%=*}"
            printf '%s= %s%s' "$prefix" "$value" "$ending" >> "$tmp"
            found=1
        else
            printf '%s%s' "$line" "$ending" >> "$tmp"
        fi
    done < "$file"

    if (( ! found )); then
        [[ -s "$tmp" ]] && [[ "$(tail -c 1 "$tmp" | od -An -tu1 | tr -d ' ')" != "10" ]] && {
            if (( crlf )); then printf '\r\n' >> "$tmp"; else printf '\n' >> "$tmp"; fi
        }
        if (( crlf )); then
            printf '%s = %s\r\n' "$key" "$value" >> "$tmp"
        else
            printf '%s = %s\n' "$key" "$value" >> "$tmp"
        fi
    fi

    chmod --reference="$file" "$tmp" 2>/dev/null || true
    mv -f "$tmp" "$file"
}

# ---------- helpers ----------

lan_ip() {
    local ip
    ip="$(ip -4 -o addr show scope global 2>/dev/null | awk '{split($4,a,"/"); print a[1]}' | head -n1)"
    [[ -z "$ip" ]] && ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
    printf '%s' "${ip:-not detected}"
}

load_values() {
    name="$(get_setting "$CONFIG" name || true)"
    port="$(get_setting "$CONFIG" port || true)"
    players="$(get_setting "$CONFIG" max_players || true)"
    password="$(get_setting "$CONFIG" password || true)"
    turn="$(get_setting "$CONFIG" turn || true)"
    mode="$(get_setting "$CONFIG" internet || true)"
    [[ -z "$port" ]] && port=7788
    [[ -z "$players" ]] && players=2
    [[ "$mode" == "1" ]] && mode=global || mode=lan
}

validate() {
    [[ -z "${name//[[:space:]]/}" ]] && { echo "Server name cannot be empty." >&2; return 1; }
    [[ "$port" =~ ^[0-9]+$ ]] && (( 10#$port >= 1 && 10#$port <= 65535 )) || {
        echo "Port must be a number from 1 to 65535." >&2; return 1; }
    [[ "$players" == 2 || "$players" == 3 || "$players" == 4 ]] || {
        echo "Max players must be 2, 3 or 4." >&2; return 1; }
    return 0
}

save_config() {
    validate || return 1
    cp -f "$CONFIG" "$BACKUP"
    set_setting "$CONFIG" name         "$name"
    set_setting "$CONFIG" port         "$port"
    set_setting "$CONFIG" max_players  "$players"
    set_setting "$CONFIG" password     "$password"
    set_setting "$CONFIG" internet     "$([[ "$mode" == global ]] && echo 1 || echo 0)"
    set_setting "$CONFIG" turn         "$turn"
    echo "Saved. Backup: $BACKUP"
}

launch_game() {
    if pgrep -f '[g]ta_sa.exe' >/dev/null 2>&1; then
        echo "GTA is already running. Close it first."
        return 1
    fi
    if [[ -x "$STARTER" ]]; then
        "$STARTER" >/dev/null 2>&1 &
    else
        ( export WINEPREFIX="$ROOT/.wine-prefix"; unset WINEARCH; cd "$ROOT" && wine gta_sa.exe ) >/dev/null 2>&1 &
    fi
    echo "GTA launched. Press F9 in game to host or join."
}

info_text() {
    if [[ "$mode" == global ]]; then
        echo "GLOBAL MODE: the mod detects your public IP, forwards UDP $port via UPnP and gives friends an invite code in F9. A password is strongly recommended. Restart GTA after applying."
    else
        echo "LAN MODE: both PCs must be on the same router. Friends connect with your LAN IP ($(lan_ip)) and port $port. Nothing else to set up. Restart GTA after applying."
    fi
}

open_config() {
    if command -v xdg-open >/dev/null 2>&1; then xdg-open "$CONFIG" >/dev/null 2>&1 &
    elif command -v gio >/dev/null 2>&1; then gio open "$CONFIG" >/dev/null 2>&1 &
    else "${EDITOR:-nano}" "$CONFIG"; fi
}

# ---------- user interface ----------

ui_whiptail() {
    local choice fields show=0
    local lan_on=off global_on=off
    [[ "$mode" == lan ]] && lan_on=on || global_on=on

    choice="$(whiptail --backtitle "GTA SA Story Co-op" \
        --title "Network Mode Switcher" \
        --radiolist "1. Choose how to play" 15 78 2 \
        "lan"    "LAN only - both PCs on the same Wi-Fi / router"    "$lan_on" \
        "global" "GLOBAL / Online - play with friends over the net" "$global_on" \
        3>&1 1>&2 2>&3)" || return 0
    mode="$choice"

    whiptail --title "Mode info" --msgbox "$(info_text)" 12 78 || return 0

    if whiptail --title "Password" --yesno "Show the password while editing?" 8 60; then show=1; fi

    name="$(whiptail --title "2. Server details" --inputbox \
        "Server name:" 9 70 "$name" 3>&1 1>&2 2>&3)" || return 0
    port="$(whiptail --title "2. Server details" --inputbox \
        "UDP port (1-65535):" 9 70 "$port" 3>&1 1>&2 2>&3)" || return 0
    players="$(whiptail --title "2. Server details" --radiolist \
        "Max players:" 13 60 3 \
        "2" "two players" "$([[ "$players" == 2 ]] && echo on || echo off)" \
        "3" "three players" "$([[ "$players" == 3 ]] && echo on || echo off)" \
        "4" "four players" "$([[ "$players" == 4 ]] && echo on || echo off)" \
        3>&1 1>&2 2>&3)" || return 0
    turn="$(whiptail --title "3. Advanced" --inputbox \
        "TURN relay (leave empty normally):\nmetered:<app>:<api-key>  or  turn:<host>:<port>:<user>:<password>" \
        12 78 "$turn" 3>&1 1>&2 2>&3)" || return 0

    if (( show )); then
        password="$(whiptail --title "Password" --inputbox \
            "Server password (empty = no password):" 9 70 "$password" 3>&1 1>&2 2>&3)" || return 0
    else
        password="$(whiptail --title "Password" --passwordbox \
            "Server password (empty = no password):" 9 70 "$password" 3>&1 1>&2 2>&3)" || return 0
    fi

    if [[ "$mode" == global && -z "$password" ]]; then
        whiptail --title "No password" --yesno \
            "Global mode with no password means anyone who finds the server can join. Continue anyway?" 9 78 \
            || return 0
    fi

    choice="$(whiptail --title "4. Apply" --menu \
        "$(info_text)" 18 82 4 \
        "save"   "Apply & Save (restart GTA to take effect)" \
        "launch" "Apply & Launch GTA" \
        "open"   "Open config file in editor" \
        "close"  "Close without applying" \
        3>&1 1>&2 2>&3)" || return 0

    case "$choice" in
        save|launch)
            validate || { whiptail --title "Error" --msgbox "Invalid settings (name, port 1-65535, players 2-4)." 8 60; return 1; }
            save_config || { whiptail --title "Error" --msgbox "Could not save config." 8 60; return 1; }
            whiptail --title "Done" --msgbox "Saved. Press F9 in game to host or join." 8 60 || true
            if [[ "$choice" == launch ]]; then
                launch_game || true
            fi
            ;;
        open) open_config ;;
        close) ;;
    esac
    return 0
}

ui_plain() {
    echo "=========================================="
    echo " GTA SA Co-op - Network Mode Switcher"
    echo "=========================================="
    echo "Current mode: $mode   LAN IP: $(lan_ip)"
    echo "Current settings: name='$name' port=$port players=$players password='$password' turn='$turn'"
    echo
    read -r -p "Mode [lan/global] (Enter = keep $mode): " answer
    [[ -n "$answer" ]] && mode="$answer"
    read -r -p "Server name (Enter = keep '$name'): " answer
    [[ -n "$answer" ]] && name="$answer"
    read -r -p "Port (Enter = keep $port): " answer
    [[ -n "$answer" ]] && port="$answer"
    read -r -p "Max players 2/3/4 (Enter = keep $players): " answer
    [[ -n "$answer" ]] && players="$answer"
    read -r -p "Password (Enter = keep current, '-' = none): " answer
    case "$answer" in
        "") ;;
        "-") password="" ;;
        *) password="$answer" ;;
    esac
    read -r -p "TURN relay (Enter = keep current, '-' = none): " answer
    case "$answer" in
        "") ;;
        "-") turn="" ;;
        *) turn="$answer" ;;
    esac
    echo
    info_text
    echo
    select action in "Apply & Save" "Apply & Launch GTA" "Open config" "Close"; do
        case "$action" in
            "Apply & Save"|"Apply & Launch GTA")
                save_config || continue
                [[ "$action" == "Apply & Launch GTA" ]] && launch_game
                break ;;
            "Open config") open_config; break ;;
            "Close") break ;;
        esac
    done
    return 0
}

# ---------- main ----------

if [[ ! -f "$CONFIG" ]]; then
    echo "Config file not found: $CONFIG" >&2
    exit 1
fi
load_values

case "${1:-}" in
    --status)
        echo "mode=$mode name=$name port=$port players=$players lan_ip=$(lan_ip)"
        exit 0 ;;
    --help|-h)
        echo "Usage: $0 [--status] [--lan|--global] [--launch]"
        echo "No arguments opens the interactive switcher."
        exit 0 ;;
esac

quick=0
[[ "${1:-}" == --lan ]]    && { mode=lan;    quick=1; }
[[ "${1:-}" == --global ]] && { mode=global; quick=1; }
if (( quick )); then
    save_config || exit 1
    if [[ "${2:-}" == --launch ]]; then
        launch_game || exit 1
    fi
    exit 0
fi

if command -v whiptail >/dev/null 2>&1 && [[ -t 0 ]]; then
    ui_whiptail
else
    ui_plain
fi
