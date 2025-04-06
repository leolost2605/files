/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.ListView : Granite.Bin {
    private static Settings list_view_settings = new Settings ("io.github.leolost2605.files.list-view");

    public Gtk.MultiSelection selection_model { get; construct; }

    private CellType sort_key {
        get {
            if (sorter.primary_sort_column == name_column) {
                return NAME;
            } else if (sorter.primary_sort_column == size_column) {
                return SIZE;
            }

            return NAME;
        }
        set {
            switch (value) {
                case NAME:
                    column_view.sort_by_column (name_column, sort_direction);
                    break;

                case SIZE:
                    column_view.sort_by_column (size_column, sort_direction);
                    break;
            }
        }
    }

    private Gtk.SortType sort_direction {
        get { return sorter.primary_sort_order; }
        set { column_view.sort_by_column (sorter.primary_sort_column, value); }
    }

    private Gtk.ColumnViewColumn name_column;
    private Gtk.ColumnViewColumn size_column;

    private Gtk.ColumnView column_view;

    private Gtk.ColumnViewSorter sorter;

    public ListView (Gtk.MultiSelection selection_model, out Gtk.Sorter sorter) {
        Object (selection_model: selection_model);

        sorter = this.sorter;
    }

    construct {
        var name_factory = new Gtk.SignalListItemFactory ();
        name_factory.setup.connect (setup_name_cell);
        name_factory.bind.connect (bind_cell);
        name_factory.unbind.connect (unbind_cell);

        var name_sorter = new Gtk.StringSorter (new Gtk.PropertyExpression (typeof (FileBase), null, "basename")) {
            ignore_case = true,
        };

        name_column = new Gtk.ColumnViewColumn (_("Name"), name_factory) {
            expand = true,
            resizable = true,
            sorter = name_sorter,
        };
        list_view_settings.bind ("name-width", name_column, "fixed-width", DEFAULT);

        var size_factory = new Gtk.SignalListItemFactory ();
        size_factory.setup.connect (setup_size_cell);
        size_factory.bind.connect (bind_cell);
        size_factory.unbind.connect (unbind_cell);

        var size_sorter = new Gtk.NumericSorter (new Gtk.PropertyExpression (typeof (FileBase), null, "size"));

        size_column = new Gtk.ColumnViewColumn (_("Size"), size_factory) {
            resizable = true,
            sorter = size_sorter
        };
        list_view_settings.bind ("size-width", size_column, "fixed-width", DEFAULT);

        column_view = new Gtk.ColumnView (selection_model) {
            hexpand = true,
            vexpand = true,
        };
        column_view.append_column (name_column);
        column_view.append_column (size_column);

        sorter = (Gtk.ColumnViewSorter) column_view.sorter;

        var scrolled_window = new Gtk.ScrolledWindow () {
            child = column_view,
            hexpand = true,
            vexpand = true,
        };

        child = scrolled_window;
        hexpand = true;
        vexpand = true;

        sorter.notify["primary-sort-column"].connect (update_action_state);
        sorter.notify["primary-sort-order"].connect (update_action_state);

        column_view.activate.connect (on_activate);
    }

    public void start_listen () {
        var action_group = (ActionGroup) get_ancestor (typeof (ActionGroup));
        action_group.action_state_changed.connect (on_action_state_changed);
    }

    public void end_listen () {
        var action_group = (ActionGroup) get_ancestor (typeof (ActionGroup));
        action_group.action_state_changed.disconnect (on_action_state_changed);
    }

    private void on_action_state_changed (string action_name, Variant state) {
        switch (action_name) {
            case MainWindow.ACTION_SORT_KEY:
                sort_key = (CellType) state.get_int32 ();
                break;

            case MainWindow.ACTION_SORT_DIRECTION:
                sort_direction = (Gtk.SortType) state.get_int32 ();
                break;
        }
    }

    private void update_action_state () {
        var action_group = (ActionGroup) get_ancestor (typeof (ActionGroup));
        action_group.change_action_state (MainWindow.ACTION_SORT_KEY, (int) sort_key);
        action_group.change_action_state (MainWindow.ACTION_SORT_DIRECTION, (int) sort_direction);
    }

    private void setup_name_cell (Object obj) {
        var item = (Gtk.ListItem) obj;
        item.child = new FileCell (NAME);
    }

    private void setup_size_cell (Object obj) {
        var item = (Gtk.ListItem) obj;
        item.child = new FileCell (SIZE);
    }

    private void bind_cell (Object obj) {
        var item = (Gtk.ListItem) obj;

        var file = (FileBase) item.item;
        file.load ();

        var cell = (FileCell) item.child;
        cell.bind (file);
    }

    private void unbind_cell (Object obj) {
        var item = (Gtk.ListItem) obj;

        var file = (FileBase) item.item;
        file.queue_unload ();

        var cell = (FileCell) item.child;
        cell.unbind ();
    }

    private void on_activate (uint position) {
        activate_action_variant (MainWindow.ACTION_PREFIX + MainWindow.ACTION_OPEN, OpenHint.NONE);
    }
}
