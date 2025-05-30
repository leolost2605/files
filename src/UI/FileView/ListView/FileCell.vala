/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.FileCell : CellBase {
    public CellType cell_type { get; construct; }

    private Binding? binding;

    private Gtk.Label label;

    public FileCell (CellType cell_type) {
        Object (cell_type: cell_type);
    }

    construct {
        label = new Gtk.Label (null) {
            halign = START
        };

        if (cell_type != NAME) {
            label.add_css_class (Granite.CssClass.DIM);
        }

        child = label;
    }

    public override void bind (FileBase file) {
        switch (cell_type) {
            case CellType.NAME:
                binding = file.bind_property ("basename", label, "label", SYNC_CREATE);
                break;
            case CellType.SIZE:
                binding = file.bind_property ("display-size", label, "label", SYNC_CREATE);
                break;
        }
    }

    public override void unbind () {
        binding.unbind ();
    }
}
