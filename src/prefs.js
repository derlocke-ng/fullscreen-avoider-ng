// Fullscreen Avoider NG preferences. A fork of Fullscreen Avoider by Noobsai,
// https://github.com/Noobsai/fullscreen-avoider (GPL-3.0-or-later).

import Adw from 'gi://Adw';
import Gdk from 'gi://Gdk';
import Gio from 'gi://Gio';
import Gtk from 'gi://Gtk';

import {ExtensionPreferences, gettext as _} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class FullscreenAvoiderPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();
        window._settings = settings;

        const page = new Adw.PreferencesPage();
        const group = new Adw.PreferencesGroup({
            description: _('While the primary monitor shows a fullscreen window, the top panel moves to another monitor.'),
        });
        page.add(group);

        group.add(this._monitorRow(settings));

        for (const [key, title, subtitle] of [
            ['move-hot-corners', _('Move Hot Corner'), _('along with the top panel')],
            ['move-notifications', _('Move Notifications'), _('banners show on the monitor with the top panel')],
        ]) {
            const row = new Adw.SwitchRow({title, subtitle});
            settings.bind(key, row, 'active', Gio.SettingsBindFlags.DEFAULT);
            group.add(row);
        }

        window.add(page);
    }

    // "Move To": Automatic, then every connected monitor by name, and the
    // saved one when it is not connected now, so the choice is not lost.
    _monitorRow(settings) {
        const choices = [['', _('Automatic'), _('the first monitor not in fullscreen')]];
        const monitors = Gdk.Display.get_default()?.get_monitors();
        for (let i = 0; i < (monitors?.get_n_items() ?? 0); i++) {
            const monitor = monitors.get_item(i);
            const connector = monitor.get_connector();
            if (!connector)
                continue;
            const {width, height} = monitor.get_geometry();
            const name = monitor.get_description() || monitor.get_model() || connector;
            choices.push([connector, name, `${connector}, ${width} × ${height}`]);
        }
        const saved = settings.get_string('target-monitor');
        if (saved && !choices.some(([c]) => c === saved))
            choices.push([saved, saved, _('not connected now')]);

        const row = new Adw.ComboRow({
            title: _('Move To'),
            subtitle: _('when it is not in fullscreen itself; otherwise the first free monitor'),
            model: Gtk.StringList.new(choices.map(([, name, detail]) => `${name} (${detail})`)),
        });
        row.set_selected(Math.max(0, choices.findIndex(([c]) => c === saved)));
        row.connect('notify::selected', () => {
            const choice = choices[row.get_selected()];
            if (choice)
                settings.set_string('target-monitor', choice[0]);
        });
        return row;
    }
}
