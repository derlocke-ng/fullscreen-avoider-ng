# Using it

GNOME shows the top panel, the hot corner and notification banners on the
*primary monitor*, the one marked as primary in Settings → Displays. When a
window covers that monitor in fullscreen, a game or a video for example,
it covers the panel too. Fullscreen Avoider NG moves these to another
monitor for as long as the fullscreen window lasts.

## What moves, and when

When a window becomes fullscreen on the primary monitor, three things move
to the target monitor (see [Choose the monitor](#choose-the-monitor)):

- **the top panel**, with the clock, the system menu and the app indicators;
- **the hot corner** of the top-left corner, which opens the overview;
- **notification banners**. GNOME holds back most banners while the primary
  monitor is in fullscreen. With the panel moved, it shows them as long as the
  panel's monitor is free.

Dragging a maximized window down from the panel works on the panel's
monitor too.

When the fullscreen window ends, or leaves the primary monitor, everything
moves back. With one monitor, the extension does nothing.

## Choose the monitor

Open the settings in the Extensions app, or with
`gnome-extensions prefs fullscreen-avoider-ng@kiwi-network.eu`.

| Setting | What it does |
|---|---|
| Move To | **Automatic** takes the first monitor that is not in fullscreen. Or pick one of your monitors by name. |
| Move Hot Corner | Moves the hot corner along with the panel. On by default. |
| Move Notifications | Shows banners on the monitor with the panel. On by default. |

A monitor is remembered by its *connector*, the port it is plugged into,
such as `DP-2` or `HDMI-1`. The list shows each monitor's name with its
connector and size. When the monitor you picked is not plugged in, or is in
fullscreen itself, the panel goes to the first free monitor instead, and
returns to your choice when it is free again. A choice for a monitor that is
not connected stays in the list as "not connected now".

Changes take effect at once, also while a fullscreen window is open.

## Known gaps

- The overview, the on-screen keyboard and the edge of the top panel that
  stops the pointer stay with the primary monitor.
- Tested in GNOME Shell 49, 50 and 51 (see
  [Development](development.md#tests)). GNOME Shell 45 to 48 are in the
  metadata as the original supports them, but untested here.
