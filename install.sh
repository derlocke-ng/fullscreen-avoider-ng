#!/usr/bin/env bash
# installer for Fullscreen Avoider NG — kiwi convention:
#   ./install.sh install|update|uninstall [--purge]
#
# User scope only: a GNOME Shell extension lives in your home folder.
#
#   ~/.local/share/gnome-shell/extensions/fullscreen-avoider-ng@kiwi-network.eu/
#
# GNOME Shell loads a new or changed extension only when you log in, so after
# an install or update: log out and back in.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION="${1:-install}"

[[ "${KIWI_SCOPE:-user}" == "user" ]] || {
    echo "error: fullscreen-avoider-ng is user-only (SCOPES=user)" >&2; exit 1; }

UUID=fullscreen-avoider-ng@kiwi-network.eu
ORIGINAL=fullscreen-avoider@noobsai.github.com
EXT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/$UUID"
SETTINGS_PATH=/org/gnome/shell/extensions/fullscreen-avoider-ng/

say() { printf ':: %s\n' "$*"; }

# kiwi exports KIWI_GUI=0/1 (as for kiwi-killswitch's extension); a standalone
# install checks for GNOME Shell itself
want_gnome() {
    [[ ${KIWI_GUI:-} == 0 ]] && return 1
    [[ -n ${KIWI_GUI:-} ]] && return 0
    command -v gnome-shell >/dev/null 2>&1
}

enabled_list() { gsettings get org.gnome.shell enabled-extensions 2>/dev/null || true; }

# Through the shell when it knows the extension; a new one it only learns
# about at the next login, so then straight into the setting it reads there.
enable_ext() {
    command -v gnome-extensions >/dev/null 2>&1 &&
        gnome-extensions enable "$UUID" 2>/dev/null && return 0
    command -v gsettings >/dev/null 2>&1 || return 0
    local cur new
    cur="$(enabled_list)"
    [[ $cur == *"'$UUID'"* ]] && return 0
    if [[ -z $cur || $cur == "@as []" || $cur == "[]" ]]; then
        new="['$UUID']"
    else
        new="${cur%]}, '$UUID']"
    fi
    gsettings set org.gnome.shell enabled-extensions "$new" 2>/dev/null || true
}

disable_ext() {
    command -v gnome-extensions >/dev/null 2>&1 &&
        gnome-extensions disable "$UUID" 2>/dev/null && return 0
    command -v gsettings >/dev/null 2>&1 || return 0
    local cur
    cur="$(enabled_list)"
    [[ $cur == *"'$UUID'"* ]] || return 0
    cur="${cur//", '$UUID'"/}"; cur="${cur//"'$UUID', "/}"; cur="${cur//"'$UUID'"/}"
    gsettings set org.gnome.shell enabled-extensions "$cur" 2>/dev/null || true
}

copy_files() {
    say "installing the extension to $EXT_DIR"
    rm -rf "${EXT_DIR:?}"
    mkdir -p "$EXT_DIR"
    cp -r "$SRC/src/." "$EXT_DIR/"
    glib-compile-schemas "$EXT_DIR/schemas"
}

warn_original() {
    if [[ "$(enabled_list)" == *"'$ORIGINAL'"* ]]; then
        say "the original Fullscreen Avoider is enabled too: turn it off, the two move the same panel"
        say "  gnome-extensions disable $ORIGINAL"
    fi
}

do_install() {
    want_gnome || { say "no GNOME Shell here (or KIWI_GUI=0) — nothing to install"; return 0; }
    copy_files
    enable_ext
    warn_original
    say "done — log out and back in (or Alt+F2 'r' on X11) to load it"
    say "  settings: gnome-extensions prefs $UUID"
}

do_update() {
    want_gnome || { say "no GNOME Shell here (or KIWI_GUI=0) — nothing to update"; return 0; }
    # an update keeps it enabled or disabled, as you left it
    copy_files
    warn_original
    say "updated — the new version runs after you log out and back in"
}

do_uninstall() {
    disable_ext
    say "removing $EXT_DIR"
    rm -rf "${EXT_DIR:?}"
    if [[ "${KIWI_PURGE:-0}" == 1 || "${1:-}" == --purge ]]; then
        say "resetting its settings"
        command -v dconf >/dev/null 2>&1 && dconf reset -f "$SETTINGS_PATH" 2>/dev/null || true
    else
        say "kept: its settings — remove them with: $0 uninstall --purge"
    fi
    say "the panel stays where it is until you log out and back in"
}

case "$ACTION" in
    install)   do_install ;;
    update)    do_update ;;
    uninstall) shift || true; do_uninstall "${1:-}" ;;
    *) echo "usage: $0 install|update|uninstall [--purge]" >&2; exit 1 ;;
esac
