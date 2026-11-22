#!/usr/bin/env bash
# tests/lint.sh — what extensions.gnome.org's review looks at and a machine can
# check: well-formed metadata, the schema, the JavaScript parses, and each
# process imports only what it may (no Gtk, Gdk or Adw in GNOME Shell; no
# Clutter, Meta, St or Shell in the preferences).
#   bash tests/lint.sh       needs python3, glib-compile-schemas, node
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fails=0
ok()  { printf 'ok   %s\n' "$*"; }
bad() { printf 'FAIL %s\n' "$*"; fails=$((fails + 1)); }
check() { local what="$1"; shift; if "$@"; then ok "$what"; else bad "$what"; fi; }

meta() { python3 -c "import json,sys; print(json.load(open('src/metadata.json'))[sys.argv[1]])" "$1"; }

check "metadata.json is valid JSON" python3 -c 'import json; json.load(open("src/metadata.json"))'
uuid="$(meta uuid)"; schema="$(meta settings-schema)"
check "the uuid is extension-id@namespace, not gnome.org" \
    bash -c '[[ $1 =~ ^[A-Za-z0-9._-]+@[A-Za-z0-9._-]+$ && $1 != *@gnome.org ]]' _ "$uuid"
check "install.sh and Makefile use the same uuid" \
    bash -c 'grep -qx "UUID=$1" install.sh && grep -qx "UUID=$1" Makefile' _ "$uuid"
check "metadata has only keys the review allows" python3 -c '
import json
allowed = {"uuid", "name", "description", "shell-version", "url", "settings-schema",
           "gettext-domain", "version-name", "session-modes", "donations"}
assert set(json.load(open("src/metadata.json"))) <= allowed'
check "the schema id starts with org.gnome.shell.extensions" bash -c '[[ $1 == org.gnome.shell.extensions.* ]]' _ "$schema"
check "the schema file is named after its id" test -f "src/schemas/$schema.gschema.xml"
check "the schema path is under /org/gnome/shell/extensions/" \
    grep -q 'path="/org/gnome/shell/extensions/' "src/schemas/$schema.gschema.xml"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cp src/schemas/*.gschema.xml "$tmp/"
check "the schema compiles (--strict)" glib-compile-schemas --strict --dry-run "$tmp"
for f in src/*.js; do
    cp "$f" "$tmp/$(basename "$f" .js).mjs"
    check "$f parses" node --check "$tmp/$(basename "$f" .js).mjs"
done
check "extension.js imports no Gtk, Gdk or Adw" bash -c "! grep -qE \"from 'gi://(Gtk|Gdk|Adw)'\" src/extension.js"
check "prefs.js imports no Clutter, Meta, St or Shell" bash -c "! grep -qE \"from 'gi://(Clutter|Meta|St|Shell)'\" src/prefs.js"
check "no eval or new Function" bash -c '! grep -nE "\beval\(|new Function\(" src/*.js'
check "the original author is credited in the shipped files" bash -c 'grep -q Noobsai src/extension.js && grep -q Noobsai src/prefs.js'

echo
if [[ $fails -gt 0 ]]; then echo "$fails failed"; exit 1; fi
echo "all passed"
