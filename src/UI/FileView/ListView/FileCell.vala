/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.FileCell : Granite.Bin {
    public CellType cell_type { get; construct; }

    private Binding? binding;

    private Gtk.Label label;

    public FileCell (CellType cell_type) {
        Object (cell_type: cell_type);
    }

    construct {
        label = new Gtk.Label (null);
        child = label;
    }

    public void bind (FileBase file) {
        switch (cell_type) {
            case CellType.NAME:
                binding = file.bind_property ("basename", label, "label", SYNC_CREATE);
                break;
            case CellType.SIZE:
                binding = file.bind_property ("size", label, "label", SYNC_CREATE);
                break;
        }
    }

    public void unbind () {
        binding.unbind ();
    }
}
