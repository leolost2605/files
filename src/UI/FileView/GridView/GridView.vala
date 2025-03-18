/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.GridView : Granite.Bin {
    public Gtk.MultiSelection selection_model { get; construct; }

    public GridView (Gtk.MultiSelection selection_model) {
        Object (selection_model: selection_model);
    }

    construct {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (setup_cell);
        factory.bind.connect (bind_cell);
        factory.unbind.connect (unbind_cell);

        var grid_view = new Gtk.GridView (selection_model, factory);

        child = grid_view;
    }

    private void setup_cell (Object obj) {
        var item = (Gtk.ListItem) obj;
        item.child = new GridCell ();
    }

    private void bind_cell (Object obj) {
        var item = (Gtk.ListItem) obj;

        var file = (FileBase) item.item;
        file.load ();

        var cell = (GridCell) item.child;
        cell.bind (file);
    }

    private void unbind_cell (Object obj) {
        var item = (Gtk.ListItem) obj;

        var file = (FileBase) item.item;
        file.queue_unload ();

        var cell = (GridCell) item.child;
        cell.unbind ();
    }
}
