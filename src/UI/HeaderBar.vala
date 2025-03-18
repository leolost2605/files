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

    public ViewType view_type {
        set {
            switch (value) {
                case LIST:
                    list_view_toggle.active = true;
                    break;

                case GRID:
                    grid_view_toggle.active = true;
                    break;
            }
        }
    }

    private Gtk.Entry path_entry;

    private Gtk.ToggleButton list_view_toggle;
    private Gtk.ToggleButton grid_view_toggle;

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

        list_view_toggle = new Gtk.ToggleButton () {
            icon_name = "view-list-symbolic",
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_SELECT_VIEW_TYPE,
            action_target = ViewType.LIST,
        };

        grid_view_toggle = new Gtk.ToggleButton () {
            icon_name = "view-grid-symbolic",
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_SELECT_VIEW_TYPE,
            action_target = ViewType.GRID,
        };
        grid_view_toggle.set_group (list_view_toggle);

        var toggles = new Gtk.Box (HORIZONTAL, 0);
        toggles.append (list_view_toggle);
        toggles.append (grid_view_toggle);

        var header_bar = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = path_entry
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);
        header_bar.pack_start (back);
        header_bar.pack_start (forward);
        header_bar.pack_end (new Gtk.WindowControls (Gtk.PackType.END));
        header_bar.pack_end (toggles);

        child = header_bar;

        path_entry.activate.connect (on_activate);
    }

    private void on_activate () {
        var uri = path_entry.text;
        activate_action_variant (MainWindow.ACTION_PREFIX + MainWindow.ACTION_GOTO, uri);
    }
}
