/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.GridCell : CellBase {
    private Binding? icon_binding;
    private Binding? label_binding;

    private Gtk.Image icon;
    private Gtk.Label label;

    construct {
        icon = new Gtk.Image () {
            pixel_size = 64
        };

        label = new Gtk.Label (null);

        var box = new Granite.Box (VERTICAL);
        box.append (icon);
        box.append (label);

        child = box;
        margin_top = 6;
        margin_bottom = 6;
        margin_start = 6;
        margin_end = 6;
    }

    public override void bind (FileBase file) {
        icon_binding = file.bind_property ("icon", icon, "gicon", SYNC_CREATE);
        label_binding = file.bind_property ("display-name", label, "label", SYNC_CREATE);
    }

    public override void unbind () {
        icon_binding?.unbind ();
        icon_binding = null;
        label_binding?.unbind ();
        label_binding = null;
    }
}
