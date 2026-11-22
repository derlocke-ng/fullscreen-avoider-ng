# Fullscreen Avoider NG

Fullscreen Avoider NG is a GNOME Shell extension for computers with more
than one monitor. While a game or a video fills your primary monitor, it
moves the top panel, the hot corner and notification banners to another
monitor, so the clock, the system menu and your notifications stay in
reach. When the fullscreen window ends, they move back. You choose which
monitor gets them, or let the extension take the first free one.

It is a fork of [Fullscreen Avoider](https://github.com/Noobsai/fullscreen-avoider)
by Noobsai, with the choice of monitor and support for GNOME 51 added. It is
part of the Kiwi desktop: apps for Fedora Atomic that
[kiwi-updater](https://github.com/derlocke-ng/kiwi-updater) installs from git
catalogs.

- Latest release: see [Releases](https://github.com/derlocke-ng/fullscreen-avoider-ng/releases)
- Runs on: GNOME Shell 45 to 51, on Wayland and X11
- License: GPL-3.0-or-later

## Install

```bash
kiwi install fullscreen-avoider-ng
```

Or from a checkout: `./install.sh install`. It copies the extension into
`~/.local/share/gnome-shell/extensions/` and turns it on, without root. GNOME
loads it the next time you log in.

Turn off the original Fullscreen Avoider if you use it: the two would move
the same panel.

## Quick start

After you log in again, open the settings in the Extensions app, or with:

```bash
gnome-extensions prefs fullscreen-avoider-ng@kiwi-network.eu
```

Pick the monitor under **Move To**, then start a game or a video in
fullscreen on your primary monitor. The top panel appears on the monitor you
picked.

## Documentation

| Page | What it covers |
|---|---|
| [Install](docs/install.md) | kiwi, a checkout, extensions.gnome.org, update, uninstall |
| [Using it](docs/usage.md) | what moves when, every setting, known gaps |
| [Development](docs/development.md) | tests, the extensions.gnome.org upload, releases |

The same pages are on [kiwi-network.eu](https://kiwi-network.eu/docs/).

## License

GPL-3.0-or-later; see [LICENSE](LICENSE). Based on Fullscreen Avoider by
Noobsai, under the same license.
