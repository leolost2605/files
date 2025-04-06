/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.SideBar : Granite.Bin {
    construct {
        var menu = new Menu ();
        menu.append (_("Show Hidden Files"), Application.ACTION_PREFIX + Application.ACTION_SHOW_HIDDEN_FILES);
        menu.append (_("Sort Folders Before Files"), Application.ACTION_PREFIX + Application.ACTION_SORT_FOLDERS_BEFORE_FILES);

        var menu_popover = new Gtk.PopoverMenu.from_model (menu);

        var menu_button = new Gtk.MenuButton () {
            icon_name = "open-menu-symbolic",
            popover = menu_popover,
        };

        var header_bar = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Grid ()
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);
        header_bar.pack_start (new Gtk.WindowControls (START));
        header_bar.pack_end (menu_button);

        var box = new Gtk.Box (VERTICAL, 0);
        box.append (header_bar);

        child = box;
    }
}
