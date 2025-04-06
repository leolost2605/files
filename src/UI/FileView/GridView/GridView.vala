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
        factory.bind.connect (CellBase.bind_func);
        factory.unbind.connect (CellBase.unbind_func);

        var grid_view = new Gtk.GridView (selection_model, factory);

        var scrolled_window = new Gtk.ScrolledWindow () {
            child = grid_view
        };

        child = scrolled_window;

        grid_view.activate.connect (on_activate);
    }

    private void setup_cell (Object obj) {
        var item = (Gtk.ListItem) obj;
        var cell = new GridCell ();
        cell.do_common_setup (item);
        item.child = cell;
    }

    private void on_activate () {
        activate_action_variant (MainWindow.ACTION_PREFIX + MainWindow.ACTION_OPEN, OpenHint.NONE);
    }
}
