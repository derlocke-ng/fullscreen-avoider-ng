#!/usr/bin/env bash
# tests/shell.sh — the extension in a real GNOME Shell: headless, with three
# virtual monitors (Meta-0, the primary, Meta-1 and Meta-2) and windows put in
# fullscreen with GTK. It checks where the panel, the hot corner and the
# notification banner are after each change, then disable and enable.
#
# Run it in a throwaway container, never on your desktop: it starts its own
# shell and buses.
#   podman run --rm -v "$PWD":/src:ro,Z -w /src registry.fedoraproject.org/fedora:45 bash -c \
#     'dnf -y -q install gnome-shell gtk4 python3-gobject dbus-daemon dbus-tools glib2 >/dev/null && \
#      dbus-run-session -- bash tests/shell.sh'
# CI runs it the same way. It needs a session bus (dbus-run-session).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UUID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["uuid"])' "$ROOT/src/metadata.json")"
WORK="$(mktemp -d)"

fails=0
ok()  { printf 'ok   %s\n' "$*"; }
bad() { printf 'FAIL %s\n' "$*"; fails=$((fails + 1)); }

# ── a session nobody logged in to ─────────────────────────────────────────
mkdir -p /run/dbus && dbus-daemon --system --fork 2>/dev/null
# no logind: without /run/systemd/seats the shell uses its stand-in
[[ -e /run/systemd/seats ]] && mv /run/systemd/seats /run/systemd/seats.off
export XDG_RUNTIME_DIR="$WORK/run" HOME="$WORK/home" GSETTINGS_BACKEND=keyfile
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
EXT="$HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXT/$UUID" "$EXT/test-helper@test"
cp -r "$ROOT/src/." "$EXT/$UUID/"
glib-compile-schemas "$EXT/$UUID/schemas"
export GSETTINGS_SCHEMA_DIR="$EXT/$UUID/schemas:/usr/share/glib-2.0/schemas"

# The shell's Eval works only in unsafe mode; this helper turns it on and
# hands Main to it. It exists only inside this test.
cat > "$EXT/test-helper@test/metadata.json" <<'EOF'
{"uuid": "test-helper@test", "name": "test helper", "description": "for tests/shell.sh", "shell-version": ["45", "46", "47", "48", "49", "50", "51"]}
EOF
cat > "$EXT/test-helper@test/extension.js" <<'EOF'
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
export default class { enable() { global.context.unsafe_mode = true; globalThis.TMain = Main; } disable() {} }
EOF
cat > "$WORK/fullscreen.py" <<'EOF'
import sys, gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gdk, Gtk
i = int(sys.argv[1])
app = Gtk.Application(application_id=f"test.Fullscreen{i}")
def activate(a):
    w = Gtk.ApplicationWindow(application=a, title=f"fullscreen {i}")
    w.present()
    w.fullscreen_on_monitor(Gdk.Display.get_default().get_monitors().get_item(i))
app.connect("activate", activate)
app.run([])
EOF

gsettings set org.gnome.shell enabled-extensions "['test-helper@test', '$UUID']"
gsettings set org.gnome.shell welcome-dialog-last-shown-version '999'
gnome-shell --headless --wayland --virtual-monitor 1280x720 --virtual-monitor 1280x720 \
    --virtual-monitor 1280x720 > "$WORK/shell.log" 2>&1 &
SHELL_PID=$!
trap 'kill $(jobs -p) 2>/dev/null; rm -rf "$WORK"' EXIT
for _ in $(seq 90); do
    gdbus call --session -d org.gnome.Shell -o /org/gnome/Shell -m org.freedesktop.DBus.Peer.Ping >/dev/null 2>&1 && break
    sleep 1
done
sleep 4

ev() { # the result of JS in the shell, or "!" and the error
    local out; out="$(gdbus call --session -d org.gnome.Shell -o /org/gnome/Shell -m org.gnome.Shell.Eval "$1" 2>&1)"
    [[ $out == "(true, '"* ]] || { echo "!$out"; return; }
    out="${out#"(true, '"}"; out="${out%"')"}"
    printf '%s' "$out" | sed 's/\\"/"/g; s/^"//; s/"$//'
}
# panel monitor | banner monitor ("p" = it follows the primary) | hot corner monitors
state() { ev "(() => { const LM = TMain.layoutManager;
    const at = x => LM.monitors.findIndex(m => m.x === x);
    const c = TMain.messageTray.get_constraints().find(k => 'primary' in k && 'index' in k);
    return [at(LM.panelBox.x), c.primary ? 'p' : c.index,
            LM.hotCorners.map((h, i) => h ? i : '').join('')].join(' '); })()"; }
expect() { # what, wanted
    local got; got="$(state)"
    if [[ $got == "$2" ]]; then ok "$1 ($got)"; else bad "$1: wanted '$2', got '$got'"; fi
}
fullscreen() { WAYLAND_DISPLAY=wayland-0 GDK_BACKEND=wayland python3 "$WORK/fullscreen.py" "$1" >/dev/null 2>&1 & echo $!; }
settle() { sleep "${1:-3}"; }

state_of() { gnome-extensions info "$UUID" 2>/dev/null | sed -n 's/^ *State: //p'; }
if [[ "$(state_of)" == ACTIVE ]]; then ok "the extension is active on $(gnome-shell --version)"
else bad "the extension is not active: $(state_of)"; grep -A3 'JS ERROR' "$WORK/shell.log" | head -20; fi
[[ "$(ev "TMain.layoutManager.monitors.length")" == 3 ]] || bad "three monitors: got $(ev "TMain.layoutManager.monitors.length")"

expect "no fullscreen: the panel stays on the primary monitor" "0 p 0"
f0=$(fullscreen 0); settle 4
expect "primary in fullscreen: automatic takes the first free monitor" "1 1 01"
gsettings set org.gnome.shell.extensions.fullscreen-avoider-ng target-monitor 'Meta-2'; settle 2
expect "Move To Meta-2: the panel follows the setting at once" "2 2 02"
f2=$(fullscreen 2); settle 4
expect "Meta-2 in fullscreen too: the first free monitor instead" "1 1 01"
kill "$f2"; settle
expect "Meta-2 free again: back to the chosen monitor" "2 2 02"
gsettings set org.gnome.shell.extensions.fullscreen-avoider-ng move-notifications false; settle 2
expect "Move Notifications off: banners stay with the primary monitor" "2 p 02"
gsettings set org.gnome.shell.extensions.fullscreen-avoider-ng move-hot-corners false; settle 2
expect "Move Hot Corner off: the corner stays on the primary monitor" "2 p 0"
gsettings reset-recursively org.gnome.shell.extensions.fullscreen-avoider-ng
gsettings set org.gnome.shell.extensions.fullscreen-avoider-ng target-monitor 'HDMI-9'; settle 2
expect "a chosen monitor that is not connected: automatic" "1 1 01"
gsettings set org.gnome.shell.extensions.fullscreen-avoider-ng target-monitor 'Meta-2'; settle 2
gnome-extensions disable "$UUID"; settle 2
expect "disabled during fullscreen: everything back on the primary monitor" "0 p 0"
gnome-extensions enable "$UUID"; settle 2
expect "enabled during fullscreen: moved again" "2 2 02"
kill "$f0"; settle
expect "fullscreen ends: back on the primary monitor" "0 p 0"
[[ "$(ev "TMain.messageTray._updateState.toString().includes('_asPanelMonitor')")" == true ]] &&
    ok "the tray asks about the panel's monitor while enabled" || bad "the tray wrapper is not in place"
gnome-extensions disable "$UUID"; settle 2
[[ "$(ev "TMain.messageTray._updateState.toString().includes('_asPanelMonitor')")" == false ]] &&
    ok "disable puts the tray's own function back" || bad "disable left the tray wrapper"

if grep -q 'JS ERROR' "$WORK/shell.log"; then
    bad "JS errors in the shell log:"; grep -A4 'JS ERROR' "$WORK/shell.log" | head -30
else
    ok "no JS errors in the shell log"
fi

kill "$SHELL_PID" 2>/dev/null
echo
if [[ $fails -gt 0 ]]; then echo "$fails failed"; exit 1; fi
echo "all passed"
