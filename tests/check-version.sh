#!/usr/bin/env bash
# Release gate: the version is the same everywhere it is written down, and the
# scripts are executable in git. The release workflow, kiwi-release and CI run it.
set -euo pipefail
cd "$(dirname "$0")/.."

rc=0
bad() { echo "check-version: $*" >&2; rc=1; }

m="$(sed -n 's/^VERSION=//p' kiwi.manifest | head -1)"
j="$(python3 -c 'import json; print(json.load(open("src/metadata.json"))["version-name"])')"
c="$(grep -m1 -oE '^## [0-9]+(\.[0-9]+)*' CHANGELOG.md | cut -c4-)"
[[ -n $m ]]     || bad "no VERSION in kiwi.manifest"
[[ $j == "$m" ]] || bad "src/metadata.json's version-name is $j, kiwi.manifest says $m"
[[ $c == "$m" ]] || bad "the newest CHANGELOG.md section is ${c:-missing}, kiwi.manifest says $m"

for f in install.sh tests/*.sh; do
    mode="$(git ls-files -s -- "$f" | cut -d' ' -f1)"
    [[ -z $mode || $mode == 100755 ]] || bad "$f is not executable in git (git update-index --chmod=+x $f)"
done

(( rc )) || echo "check-version: ok ($m)"
exit $rc
