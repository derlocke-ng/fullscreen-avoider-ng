#!/usr/bin/env bash
# tests/install.sh — install.sh install, update and uninstall into a throwaway
# $HOME, with the keyfile settings backend so nothing reaches your dconf.
#   bash tests/install.sh        needs glib-compile-schemas and gsettings
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fails=0
ok()  { printf 'ok   %s\n' "$*"; }
bad() { printf 'FAIL %s\n' "$*"; fails=$((fails + 1)); }
check() { local what="$1"; shift; if "$@"; then ok "$what"; else bad "$what"; fi; }

H="$WORK/home"; mkdir -p "$H"
UUID=fullscreen-avoider-ng@kiwi-network.eu
DIR="$H/.local/share/gnome-shell/extensions/$UUID"
# no gnome-extensions on PATH: the installer has to manage with gsettings
mkdir -p "$WORK/bin"
for c in bash glib-compile-schemas gsettings dconf cp rm mkdir cat sed grep printf dirname; do
    p="$(command -v "$c" 2>/dev/null)" && ln -sf "$p" "$WORK/bin/$c"
done
run() { env -i HOME="$H" PATH="$WORK/bin" GSETTINGS_BACKEND=keyfile KIWI_GUI="${GUI:-1}" \
            XDG_CONFIG_HOME="$H/.config" bash "$ROOT/install.sh" "$@"; }
enabled() { env -i HOME="$H" XDG_CONFIG_HOME="$H/.config" GSETTINGS_BACKEND=keyfile \
                gsettings get org.gnome.shell enabled-extensions; }
setenabled() { env -i HOME="$H" XDG_CONFIG_HOME="$H/.config" GSETTINGS_BACKEND=keyfile \
                   gsettings set org.gnome.shell enabled-extensions "$1"; }

setenabled "['other@example.com']"
run install > "$WORK/out" 2>&1; rc=$?
check "install exits 0" test "$rc" -eq 0
[[ $rc -eq 0 ]] || cat "$WORK/out"
check "the extension is in place" test -f "$DIR/extension.js" -a -f "$DIR/metadata.json" -a -f "$DIR/prefs.js"
check "its schema is compiled" test -f "$DIR/schemas/gschemas.compiled"
check "install enables it, next to what was enabled" test "$(enabled)" = "['other@example.com', '$UUID']"

setenabled "['other@example.com']"     # you turned it off
echo stale > "$DIR/old-file.js"
run update > /dev/null 2>&1
check "update keeps it off when you turned it off" test "$(enabled)" = "['other@example.com']"
check "update replaces the files, nothing old stays" test ! -e "$DIR/old-file.js"

setenabled "['$UUID', 'fullscreen-avoider@noobsai.github.com']"
out="$(run update 2>&1)"
check "update warns when the original extension is enabled too" grep -q 'original Fullscreen Avoider' <<<"$out"

setenabled "['a@b', '$UUID', 'c@d']"
run uninstall > /dev/null 2>&1
check "uninstall removes the files" test ! -e "$DIR"
check "uninstall takes it off the enabled list only" test "$(enabled)" = "['a@b', 'c@d']"

GUI=0 run install > "$WORK/out" 2>&1
check "without GNOME (KIWI_GUI=0) nothing is installed" test ! -e "$DIR"

echo
if [[ $fails -gt 0 ]]; then echo "$fails failed"; exit 1; fi
echo "all passed"
