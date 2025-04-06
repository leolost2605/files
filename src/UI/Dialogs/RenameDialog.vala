/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.RenameDialog : Gtk.Window {
    public FileBase file { get; construct; }

    private Gtk.Entry new_name_entry;

    public RenameDialog (FileBase file) {
        Object (file: file);
    }

    construct {
        var header_bar = new Gtk.HeaderBar ();
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);

        new_name_entry = new Gtk.Entry () {
            text = file.basename,
            activates_default = true,
        };

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var rename_button = new Gtk.Button.with_label (_("Rename"));
        rename_button.add_css_class (Granite.CssClass.SUGGESTED);

        var button_box = new Granite.Box (HORIZONTAL, SINGLE) {
            halign = END,
            homogeneous = true,
        };
        button_box.append (cancel_button);
        button_box.append (rename_button);

        var main_box = new Granite.Box (VERTICAL, SINGLE) {
            hexpand = true,
            vexpand = true,
            margin_end = 12,
            margin_start = 12,
            margin_top = 12,
            margin_bottom = 12,
        };
        main_box.append (new_name_entry);
        main_box.append (button_box);

        titlebar = header_bar;
        title = (file is Directory) ? _("Rename Folder") : _("Rename File");
        child = main_box;
        resizable = false;
        default_height = -1;
        default_width = 250;
        default_widget = rename_button;

        cancel_button.clicked.connect (close);
        rename_button.clicked.connect (rename);
    }

    private void rename () {
        OperationManager.get_instance ().rename_files ({ file.uri }, { new_name_entry.text });
        close ();
    }
}
