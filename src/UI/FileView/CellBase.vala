/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public abstract class Files.CellBase : Granite.Bin {
    public uint position { get; set; }

    public abstract void bind (FileBase file);
    public abstract void unbind ();

    public void do_common_setup (Gtk.ListItem item) {
        item.bind_property ("position", this, "position", SYNC_CREATE);
    }

    public static void bind_func (Object obj) {
        var item = (Gtk.ListItem) obj;

        var file = (FileBase) item.item;
        file.load ();

        var cell = (CellBase) item.child;
        cell.bind (file);
    }

    public static void unbind_func (Object obj) {
        var item = (Gtk.ListItem) obj;

        var file = (FileBase) item.item;
        file.queue_unload ();

        var cell = (CellBase) item.child;
        cell.unbind ();
    }
}
