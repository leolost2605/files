/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public abstract class Files.CellBase : Granite.Bin {
    public uint position { get; set; }

    private Binding? sensitive_binding;

    public abstract void bind (FileBase file);
    public abstract void unbind ();

    public void do_common_setup (Gtk.ListItem item) {
        item.bind_property ("position", this, "position", SYNC_CREATE);
    }

    private void bind_common (FileBase file) {
        file.load ();
        file.bind_property ("move-queued", this, "sensitive", SYNC_CREATE | INVERT_BOOLEAN);
    }

    private void unbind_common (FileBase file) {
        file.queue_unload ();
        sensitive_binding?.unbind ();
        sensitive_binding = null;
    }

    public static void bind_func (Object obj) {
        var item = (Gtk.ListItem) obj;

        var file = (FileBase) item.item;

        var cell = (CellBase) item.child;
        cell.bind_common (file);
        cell.bind (file);
    }

    public static void unbind_func (Object obj) {
        var item = (Gtk.ListItem) obj;

        var file = (FileBase) item.item;

        var cell = (CellBase) item.child;
        cell.unbind_common (file);
        cell.unbind ();
    }
}
