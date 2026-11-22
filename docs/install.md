# Install

Fullscreen Avoider NG runs on GNOME Shell 45 to 51. It installs for your user
only, into `~/.local/share/gnome-shell/extensions/`, and needs no root.

GNOME Shell loads a new or changed extension only when you log in. After an
install or an update, log out and back in. On X11 you can instead press
Alt+F2, type `r` and press Enter.

## With kiwi

```bash
kiwi install fullscreen-avoider-ng
```

[kiwi-updater](https://github.com/derlocke-ng/kiwi-updater) keeps it up to
date from then on. kiwi needs `glib-compile-schemas` for it, which comes with
GLib on every GNOME system.

## From a checkout

```bash
git clone https://github.com/derlocke-ng/fullscreen-avoider-ng.git
cd fullscreen-avoider-ng
./install.sh install
```

The installer copies `src/` to
`~/.local/share/gnome-shell/extensions/fullscreen-avoider-ng@kiwi-network.eu/`,
compiles the settings schema there, and adds the extension to the ones GNOME
turns on at login.

## From extensions.gnome.org

An upload to extensions.gnome.org is planned. Until the site lists it, use
kiwi or a checkout.

## The original Fullscreen Avoider

This extension is a fork of Fullscreen Avoider and has its own name and ID
(`fullscreen-avoider-ng@kiwi-network.eu`), so both can be installed. Do not
turn both on: each would move the same panel. The installer says so when it
finds the original turned on. Turn it off with:

```bash
gnome-extensions disable fullscreen-avoider@noobsai.github.com
```

Your settings of the original are not taken over; set the two switches again.

## Update

`kiwi update` installs a new release; from a checkout, pull and run
`./install.sh update`. An update keeps the extension turned on or off, as you
left it, and keeps your settings.

## Uninstall

```bash
kiwi uninstall fullscreen-avoider-ng      # or: ./install.sh uninstall
```

This turns the extension off and removes its files. Your settings stay;
`--purge` resets them too. The panel goes back to the primary monitor when
you log out and back in.
