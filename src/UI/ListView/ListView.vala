/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.ListView : Granite.Bin {
    public signal void file_activated (FileBase file);

    public Gtk.MultiSelection selection_model { get; construct; }

    public ListView (Gtk.MultiSelection selection_model) {
        Object (selection_model: selection_model);
    }

    construct {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (setup_file_row);
        factory.bind.connect (bind_file_row);
        factory.unbind.connect (unbind_file_row);

        var list_view = new Gtk.ListView (selection_model, factory) {
            hexpand = true,
            vexpand = true,
        };

        var scrolled_window = new Gtk.ScrolledWindow () {
            child = list_view,
            hexpand = true,
            vexpand = true,
        };

        child = scrolled_window;

        list_view.activate.connect (on_activate);
    }

    private void setup_file_row (Object obj) {
        var item = (Gtk.ListItem) obj;
        item.child = new FileRow ();
    }

    private void bind_file_row (Object obj) {
        var item = (Gtk.ListItem) obj;

        var file = (FileBase) item.item;
        file.load ();

        var row = (FileRow) item.child;
        row.bind (file);
    }

    private void unbind_file_row (Object obj) {
        var item = (Gtk.ListItem) obj;

        var file = (FileBase) item.item;
        file.queue_unload ();
    }

    private void on_activate (uint position) {
        var file = (FileBase) selection_model.get_item (position);
        file_activated (file);
    }
}
