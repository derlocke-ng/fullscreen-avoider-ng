// Fullscreen Avoider NG: while the primary monitor shows a fullscreen window,
// the top panel, the hot corner and notification banners move to another
// monitor, and they come back when the fullscreen ends.
//
// A fork of Fullscreen Avoider by Noobsai,
// https://github.com/Noobsai/fullscreen-avoider (GPL-3.0-or-later).

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Layout from 'resource:///org/gnome/shell/ui/layout.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import Meta from 'gi://Meta';

export default class FullscreenAvoider extends Extension {
    enable() {
        const LM = Main.layoutManager;
        const MT = Main.messageTray;
        this._settings = this.getSettings();
        this._panelIndex = -1;

        // The banner follows this constraint: the primary monitor, or the
        // monitor we give it.
        this._constraint = MT.get_constraints().find(c => c instanceof Layout.MonitorConstraint) ?? null;

        // The tray holds banners back while the PRIMARY monitor is in
        // fullscreen. With the panel on another monitor, it should ask about
        // that one: for the time of the call, the panel's monitor stands in
        // for the primary one.
        const ext = this;
        this._origUpdateState = MT._updateState;
        MT._updateState = function (...args) {
            return ext._asPanelMonitor(() => ext._origUpdateState.apply(this, args));
        };

        // Dragging a maximized window down from the panel only looks at
        // windows on the primary monitor; look at the panel's monitor.
        this._origDraggable = Main.panel._getDraggableWindowForPosition;
        Main.panel._getDraggableWindowForPosition = stageX => this._draggableWindow(stageX);

        this._fullscreenId = global.display.connect('in-fullscreen-changed', () => this._update());
        // The shell puts the panel back on the primary monitor when monitors
        // change; place it again after that.
        this._monitorsId = LM.connect('monitors-changed', () => {
            this._panelIndex = -1;
            this._update();
        });
        this._settingsId = this._settings.connect('changed', () => {
            this._panelIndex = -1;
            this._update();
        });

        this._update();
    }

    disable() {
        const LM = Main.layoutManager;
        global.display.disconnect(this._fullscreenId);
        LM.disconnect(this._monitorsId);
        this._settings.disconnect(this._settingsId);

        Main.messageTray._updateState = this._origUpdateState;
        Main.panel._getDraggableWindowForPosition = this._origDraggable;

        // Everything back where the shell keeps it
        if (this._constraint)
            this._constraint.primary = true;
        LM._updateBoxes();
        LM._updateHotCorners();
        LM._updateVisibility();

        this._settings = null;
        this._constraint = null;
        this._origUpdateState = null;
        this._origDraggable = null;
        this._fullscreenId = 0;
        this._monitorsId = 0;
        this._settingsId = 0;
    }

    // The monitor the panel belongs on now: the primary one unless it is in
    // fullscreen; then the chosen monitor, if it is connected and not in
    // fullscreen itself; else the first monitor that is not in fullscreen.
    _target() {
        const LM = Main.layoutManager;
        const primary = LM.primaryMonitor;
        if (!primary || LM.monitors.length < 2 || !primary.inFullscreen)
            return primary;

        const connector = this._settings.get_string('target-monitor');
        if (connector) {
            const index = global.backend.get_monitor_manager().get_monitor_for_connector(connector);
            const chosen = LM.monitors[index];
            if (chosen && index !== LM.primaryIndex && !chosen.inFullscreen)
                return chosen;
        }
        return LM.monitors.find(m => !m.inFullscreen) ?? primary;
    }

    _update() {
        const monitor = this._target();
        if (!monitor || monitor.index === this._panelIndex)
            return;
        this._panelIndex = monitor.index;

        const LM = Main.layoutManager;
        const moved = monitor.index !== LM.primaryIndex;

        if (moved) {
            LM.panelBox.set_position(monitor.x, monitor.y);
            LM.panelBox.set_size(monitor.width, -1);
            LM.panelBox.visible = true;
        } else {
            LM._updateBoxes();
            LM._updateVisibility();
        }

        if (moved && this._settings.get_boolean('move-hot-corners')) {
            // the shell builds the full hot corner on the primary monitor
            const primaryIndex = LM.primaryIndex;
            LM.primaryIndex = monitor.index;
            try {
                LM._updateHotCorners();
            } finally {
                LM.primaryIndex = primaryIndex;
            }
        } else {
            LM._updateHotCorners();
        }

        if (this._constraint) {
            if (moved && this._settings.get_boolean('move-notifications'))
                this._constraint.index = monitor.index;
            else
                this._constraint.primary = true;
        }
    }

    _panelMonitor() {
        const LM = Main.layoutManager;
        return LM.monitors[this._panelIndex] ?? LM.primaryMonitor;
    }

    _asPanelMonitor(call) {
        const LM = Main.layoutManager;
        const monitor = this._panelMonitor();
        if (!this._settings.get_boolean('move-notifications') || !monitor || monitor === LM.primaryMonitor)
            return call();
        const primary = LM.primaryMonitor;
        LM.primaryMonitor = monitor;
        try {
            return call();
        } finally {
            LM.primaryMonitor = primary;
        }
    }

    // GNOME Shell's Panel._getDraggableWindowForPosition, for the panel's
    // monitor instead of the primary one
    _draggableWindow(stageX) {
        const index = this._panelMonitor()?.index ?? -1;
        const windows = global.workspace_manager.get_active_workspace().list_windows();
        return global.display.sort_windows_by_stacking(windows).reverse().find(metaWindow => {
            const rect = metaWindow.get_frame_rect();
            return metaWindow.get_monitor() === index &&
                   metaWindow.showing_on_its_workspace() &&
                   metaWindow.get_window_type() !== Meta.WindowType.DESKTOP &&
                   metaWindow.maximized_vertically &&
                   stageX > rect.x && stageX < rect.x + rect.width;
        });
    }
}
