/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.FileRow : Granite.Bin {
    private Gtk.Label basename_label;

    construct {
        basename_label = new Gtk.Label (null);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.append (basename_label);

        child = box;
    }

    public void bind (FileBase file) {
        basename_label.label = file.basename;
    }
}
