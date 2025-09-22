/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.Sidebar : Granite.Bin {
    private ListStore special_locations;

    construct {
        var menu = new Menu ();
        menu.append (_("Show Hidden Files"), Application.ACTION_PREFIX + Application.ACTION_SHOW_HIDDEN_FILES);
        menu.append (_("Sort Folders Before Files"), Application.ACTION_PREFIX + Application.ACTION_SORT_FOLDERS_BEFORE_FILES);

        var menu_popover = new Gtk.PopoverMenu.from_model (menu);

        var menu_button = new Gtk.MenuButton () {
            icon_name = "open-menu-symbolic",
            popover = menu_popover,
        };

        var header_bar = new Adw.HeaderBar () {
            show_title = false
        };
        header_bar.pack_end (menu_button);

        special_locations = new ListStore (typeof (FileBase));

        var special_locations_section = new SidebarSection (special_locations);

        var content_box = new Gtk.Box (VERTICAL, 0);
        content_box.append (special_locations_section);

        var scrolled = new Gtk.ScrolledWindow () {
            child = content_box,
            vexpand = true,
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = scrolled
        };
        toolbar_view.add_top_bar (header_bar);

        child = toolbar_view;

        load_special_locations.begin ();
    }

    private async void load_special_locations () {
        special_locations.append (yield Utils.get_home_directory ());
        special_locations.append (yield Utils.get_special_directory (UserDirectory.DESKTOP));
        special_locations.append (yield Utils.get_special_directory (UserDirectory.DOWNLOAD));
        special_locations.append (yield Utils.get_special_directory (UserDirectory.MUSIC));
        special_locations.append (yield Utils.get_special_directory (UserDirectory.PICTURES));
        special_locations.append (yield Utils.get_special_directory (UserDirectory.VIDEOS));
        special_locations.append (yield Utils.get_special_directory (UserDirectory.DOCUMENTS));
        special_locations.append (yield Files.Utils.get_trash_directory ());
    }
}
