/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.HeaderBar : Granite.Bin {
    private Gtk.Entry path_entry;

    construct {
        path_entry = new Gtk.Entry () {
            hexpand = true,
        };

        var back = new Gtk.Button.from_icon_name ("go-previous") {
            action_name = MainWindow.ACTION_PREFIX + FileViewState.ACTION_BACK,
        };
        back.add_css_class (Granite.STYLE_CLASS_FLAT);
        back.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);

        var forward = new Gtk.Button.from_icon_name ("go-next") {
            action_name = MainWindow.ACTION_PREFIX + FileViewState.ACTION_FORWARD,
        };
        forward.add_css_class (Granite.STYLE_CLASS_FLAT);
        forward.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);

        var list_view_toggle = new Gtk.ToggleButton () {
            icon_name = "view-list-symbolic",
            action_name = MainWindow.ACTION_PREFIX + FileViewState.ACTION_VIEW_TYPE,
            action_target = Utils.enum_to_nick (typeof (ViewType), ViewType.LIST),
            valign = CENTER,
        };

        var grid_view_toggle = new Gtk.ToggleButton () {
            icon_name = "view-grid-symbolic",
            action_name = MainWindow.ACTION_PREFIX + FileViewState.ACTION_VIEW_TYPE,
            action_target = Utils.enum_to_nick (typeof (ViewType), ViewType.GRID),
            valign = CENTER,
        };

        var toggles = new Granite.Box (HORIZONTAL, LINKED);
        toggles.append (list_view_toggle);
        toggles.append (grid_view_toggle);

        var sort_key_section = new Menu ();
        var name_action = Action.print_detailed_name (MainWindow.ACTION_PREFIX + FileViewState.ACTION_SORT_KEY, Utils.enum_to_nick (typeof (CellType), CellType.NAME));
        sort_key_section.append (_("Name"), name_action);
        var size_action = Action.print_detailed_name (MainWindow.ACTION_PREFIX + FileViewState.ACTION_SORT_KEY, Utils.enum_to_nick (typeof (CellType), CellType.SIZE));
        sort_key_section.append (_("Size"), size_action);

        var sort_direction_section = new Menu ();
        var ascending_action = Action.print_detailed_name (MainWindow.ACTION_PREFIX + FileViewState.ACTION_SORT_DIRECTION, Utils.enum_to_nick (typeof (Gtk.SortType), Gtk.SortType.ASCENDING));
        sort_direction_section.append (_("Ascending"), ascending_action);
        var descending_action = Action.print_detailed_name (MainWindow.ACTION_PREFIX + FileViewState.ACTION_SORT_DIRECTION, Utils.enum_to_nick (typeof (Gtk.SortType), Gtk.SortType.DESCENDING));
        sort_direction_section.append (_("Descending"), descending_action);

        var sort_menu = new Menu ();
        sort_menu.append_section (null, sort_key_section);
        sort_menu.append_section (null, sort_direction_section);

        var sort_popover = new Gtk.PopoverMenu.from_model (sort_menu);

        var sort_button = new Gtk.MenuButton () {
            popover = sort_popover
        };

        var header_bar = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = path_entry
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);
        header_bar.pack_start (back);
        header_bar.pack_start (forward);
        header_bar.pack_end (new Gtk.WindowControls (Gtk.PackType.END));
        header_bar.pack_end (sort_button);
        header_bar.pack_end (toggles);

        child = header_bar;

        map.connect (on_map);

        path_entry.activate.connect (on_activate);
    }

    private void on_map () {
        var main_window = (MainWindow) get_ancestor (typeof (MainWindow));
        if (main_window != null) {
            main_window.action_added.connect (on_action_added);
            main_window.action_state_changed.connect (on_action_state_changed);
        }
    }

    private void on_action_added (ActionGroup group, string action_name) {
        if (action_name == FileViewState.ACTION_LOCATION) {
            on_action_state_changed (action_name, group.get_action_state (action_name));
        }
    }

    private void on_action_state_changed (string action, Variant new_state) {
        if (action == FileViewState.ACTION_LOCATION) {
            path_entry.text = new_state.get_string ();
        }
    }

    private void on_activate () {
        var uri = path_entry.text;
        activate_action_variant (MainWindow.ACTION_PREFIX + FileViewState.ACTION_LOCATION, uri);
    }
}
