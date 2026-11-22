# Changelog

Releases of Fullscreen Avoider NG. The newest is on top; its heading is the
version in kiwi.manifest and metadata.json (`version-name`).

## 1.0.1 — 2026-11-22

- **A fitting icon.** kiwi showed the kiwi-icons "monitor" glyph, which is a
  heartbeat line. It is now the kiwi-os glyph in graphite. The extension
  itself is unchanged.

## 1.0.0 — 2026-11-22

The first release of the fork of Fullscreen Avoider by Noobsai (its v13).

- **Move To:** choose the monitor that gets the top panel, the hot corner
  and notification banners, or let it take the first free one (as before).
  When the chosen monitor is not connected or is in fullscreen itself, the
  first free monitor is used. A setting change takes effect at once.
- **GNOME Shell 51.**
- **Its own name and ID**, `fullscreen-avoider-ng@kiwi-network.eu`, so it can
  go on extensions.gnome.org next to the original. Settings of the original
  are not taken over.
- **No more rewriting GNOME Shell's code as text.** The original patched two
  shell functions by editing their source and running it with `new
  Function`. They are now wrapped, and the originals are put back on
  disable. A dragged maximized window is now looked for on the panel's
  monitor, not on every monitor.
- **Monitor changes:** after monitors are plugged in or out, the panel is
  placed again instead of staying on the primary monitor.
- **Disable hands the notification banner back to GNOME.** Before, it stayed
  fixed to the monitor that was primary at that moment, also after you made
  another monitor the primary one.
- **kiwi:** `kiwi.manifest`, `install.sh`, CI with a headless GNOME Shell
  test on GNOME 49, 50 and 51, signed releases.
