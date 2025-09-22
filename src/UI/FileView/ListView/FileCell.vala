/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.FileCell : CellBase {
    public CellType cell_type { get; construct; }

    private Binding? icon_binding;
    private Binding? label_binding;

    private Gtk.Image? icon;
    private Gtk.Label label;

    public FileCell (CellType cell_type) {
        Object (cell_type: cell_type);
    }

    construct {
        if (cell_type == NAME) {
            icon = new Gtk.Image () {
                pixel_size = 32,
                valign = CENTER
            };
        }

        label = new Gtk.Label (null) {
            halign = START
        };

        if (cell_type != NAME) {
            label.add_css_class (Granite.CssClass.DIM);
        }

        var box = new Granite.Box (HORIZONTAL);
        if (icon != null) {
            box.append (icon);
        }
        box.append (label);

        child = box;
    }

    public override void bind (FileBase file) {
        switch (cell_type) {
            case CellType.NAME:
                icon_binding = file.bind_property ("icon", icon, "gicon", SYNC_CREATE);
                label_binding = file.bind_property ("basename", label, "label", SYNC_CREATE);
                break;
            case CellType.SIZE:
                label_binding = file.bind_property ("display-size", label, "label", SYNC_CREATE);
                break;
        }
    }

    public override void unbind () {
        icon_binding?.unbind ();
        icon_binding = null;
        label_binding?.unbind ();
        label_binding = null;
    }
}
