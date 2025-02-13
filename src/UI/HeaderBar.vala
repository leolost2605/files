/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.HeaderBar : Granite.Bin {
    public Directory? directory {
        set {
            if (value != null) {
                path_entry.text = value.uri;
            }
        }
    }

    private Gtk.Entry path_entry;

    construct {
        path_entry = new Gtk.Entry () {
            hexpand = true,
        };

        var back = new Gtk.Button.from_icon_name ("go-previous") {
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_BACK,
        };
        back.add_css_class (Granite.STYLE_CLASS_FLAT);
        back.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);

        var forward = new Gtk.Button.from_icon_name ("go-next") {
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_FORWARD,
        };
        forward.add_css_class (Granite.STYLE_CLASS_FLAT);
        forward.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);

        var header_bar = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = path_entry
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);
        header_bar.pack_start (back);
        header_bar.pack_start (forward);
        header_bar.pack_end (new Gtk.WindowControls (Gtk.PackType.END));

        child = header_bar;

        path_entry.activate.connect (on_activate);
    }

    private void on_activate () {
        var uri = path_entry.text;
        activate_action_variant (MainWindow.ACTION_PREFIX + MainWindow.ACTION_GOTO, uri);
    }
}
