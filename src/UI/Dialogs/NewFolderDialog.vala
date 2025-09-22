/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.NewFolderDialog : Gtk.Window {
    public signal void create_folder (string name);

    private Gtk.Entry name_entry;

    construct {
        var header_bar = new Gtk.HeaderBar ();
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);

        name_entry = new Gtk.Entry () {
            placeholder_text = _("Enter folder name"),
            activates_default = true,
        };

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var create_button = new Gtk.Button.with_label (_("Create"));
        create_button.add_css_class (Granite.CssClass.SUGGESTED);

        var button_box = new Granite.Box (HORIZONTAL, SINGLE) {
            halign = END,
            homogeneous = true,
        };
        button_box.append (cancel_button);
        button_box.append (create_button);

        var main_box = new Granite.Box (VERTICAL, SINGLE) {
            hexpand = true,
            vexpand = true,
            margin_end = 12,
            margin_start = 12,
            margin_top = 12,
            margin_bottom = 12,
        };
        main_box.append (name_entry);
        main_box.append (button_box);

        titlebar = header_bar;
        title = _("New Folder");
        child = main_box;
        resizable = false;
        default_height = -1;
        default_width = 250;
        default_widget = create_button;

        cancel_button.clicked.connect (close);
        create_button.clicked.connect (create);
    }

    private void create () {
        create_folder (name_entry.text);
        close ();
    }
}
