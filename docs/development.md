# Development

This page is for people who change Fullscreen Avoider NG: where things are,
how to test, how to publish on extensions.gnome.org and how to release.

## Layout

```
fullscreen-avoider-ng/
├── src/                 the extension, exactly as it is installed
│   ├── extension.js     runs in GNOME Shell
│   ├── prefs.js         the settings window, a separate process
│   ├── metadata.json
│   └── schemas/         the GSettings schema
├── install.sh           kiwi's installer: install, update, uninstall
├── kiwi.manifest        what kiwi knows about it
├── data/                the icon kiwi shows
├── tests/               check-version.sh, lint.sh, install.sh, shell.sh
└── Makefile             make pack, make install, make test
```

The extension wraps two functions of GNOME Shell while it is on and puts the
originals back in `disable()`. `MessageTray._updateState` runs with the
panel's monitor standing in for the primary one, and
`Panel._getDraggableWindowForPosition` looks at windows on the panel's
monitor. It reads no code as text and uses no `eval`.

## Tests

| Test | What it checks | Where |
|---|---|---|
| `bash tests/check-version.sh` | the version is the same in `kiwi.manifest`, `metadata.json` (`version-name`) and `CHANGELOG.md`; the scripts are executable in git | anywhere |
| `bash tests/lint.sh` | what the extensions.gnome.org review checks: metadata keys, the UUID, the schema's ID, path and name, that the JavaScript parses, the imports each process may use, no `eval` | anywhere, with `node` and `glib-compile-schemas` |
| `bash tests/install.sh` | install, update (on or off as you left it) and uninstall into a throwaway `$HOME` | anywhere |
| `tests/shell.sh` | the extension in a real, headless GNOME Shell with three virtual monitors and fullscreen windows: every setting, disable and enable, no JS errors | a container |

`tests/shell.sh` starts its own GNOME Shell and buses, so run it in a
throwaway container, never on your desktop:

```bash
podman run --rm -v "$PWD":/src:ro,Z -w /src registry.fedoraproject.org/fedora:45 bash -c \
  'dnf -y -q install gnome-shell gtk4 python3-gobject dbus-daemon dbus-tools glib2 >/dev/null && \
   dbus-run-session -- bash tests/shell.sh'
```

CI runs all four, `shellcheck` and the docs check. It runs `tests/shell.sh`
on Fedora 43, 44 and 45, which have GNOME Shell 49, 50 and 51.

## Publish on extensions.gnome.org

```bash
make pack
```

This writes `build/fullscreen-avoider-ng@kiwi-network.eu.shell-extension.zip`
with `gnome-extensions pack`: `extension.js`, `prefs.js`, `metadata.json` and
the schema. Upload it at <https://extensions.gnome.org/upload/>, signed in
with your account there. The site sets its own version number and compiles
the schema. A person reviews each upload, so the extension appears after
that review.

When a new GNOME Shell comes out: check its porting guide on gjs.guide, add
the version to `shell-version` in `metadata.json`, add the Fedora release to
the CI matrix, and upload a new zip.

## Release

1. Raise the version in `kiwi.manifest` (`VERSION`) and `src/metadata.json`
   (`version-name`), and add its section to `CHANGELOG.md`.
2. Merge to `main`, date the changelog section there, then sign and push the
   tag with kiwi-updater's `kiwi-release tag --push`. The release workflow
   publishes a signed `v*` tag and never makes one itself.

kiwi installs the newest version tag. kiwi-network.eu pulls `docs/` at that
tag.
