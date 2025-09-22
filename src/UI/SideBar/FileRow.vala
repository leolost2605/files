/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.FileRow : Gtk.ListBoxRow {
    public FileBase file { get; construct; }

    public FileRow (FileBase file) {
        Object (file: file);
    }

    construct {
        var icon = new Gtk.Image () {
            icon_size = NORMAL
        };
        file.bind_property ("icon", icon, "gicon", SYNC_CREATE);

        var label = new Gtk.Label (null) {
            xalign = 0
        };
        file.bind_property ("basename", label, "label", SYNC_CREATE);

        var box = new Granite.Box (HORIZONTAL);
        box.append (icon);
        box.append (label);

        child = box;
    }
}
