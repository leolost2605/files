/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.SidebarSection : Granite.Bin {
    public ListModel locations { get; construct; }

    private Gtk.ListBox list_box;

    public SidebarSection (ListModel locations) {
        Object (locations: locations);
    }

    construct {
        list_box = new Gtk.ListBox () {
            selection_mode = SINGLE
        };
        list_box.add_css_class (Granite.STYLE_CLASS_SIDEBAR);
        list_box.bind_model (locations, create_row_func);
        list_box.row_activated.connect (on_row_activated);

        child = list_box;

        map.connect (on_map);
    }

    private Gtk.Widget create_row_func (Object obj) {
        var file = (FileBase) obj;
        return new FileRow (file);
    }

    private void on_row_activated (Gtk.ListBoxRow row) {
        var file_row = (FileRow) row;
        activate_action_variant (MainWindow.ACTION_PREFIX + FileViewState.ACTION_LOCATION, file_row.file.uri);
    }

    private void on_map () {
        var main_window = (MainWindow) get_ancestor (typeof(MainWindow));
        if (main_window != null) {
            main_window.location_changed.connect (on_location_changed);
        }
    }

    private void on_location_changed (string new_location) {
        list_box.unselect_all ();

        for (int i = 0; i < locations.get_n_items (); i++) {
            var file = (FileBase) locations.get_item (i);

            if (file.uri != new_location) {
                continue;
            }

            var row = list_box.get_row_at_index (i);
            if (row != null) {
                list_box.select_row (row);
            }

            break;
        }
    }
}
