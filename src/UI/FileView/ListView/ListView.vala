/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.ListView : Granite.Bin {
    private static Settings list_view_settings = new Settings ("io.github.leolost2605.files.list-view");

    public FileViewState state { get; construct; }
    public Gtk.MultiSelection selection_model { get; construct; }

    private Gtk.ColumnView column_view;

    private Gtk.ColumnViewSorter sorter;

    public ListView (FileViewState state, Gtk.MultiSelection selection_model, out Gtk.Sorter sorter) {
        Object (state: state, selection_model: selection_model);

        sorter = this.sorter;
    }

    construct {
        var name_factory = new Gtk.SignalListItemFactory ();
        name_factory.setup.connect (setup_name_cell);
        name_factory.bind.connect (CellBase.bind_func);
        name_factory.unbind.connect (CellBase.unbind_func);

        var name_sorter = new Gtk.StringSorter (new Gtk.PropertyExpression (typeof (FileBase), null, "basename")) {
            ignore_case = true,
        };

        var name_column = new Gtk.ColumnViewColumn (_("Name"), name_factory) {
            id = CellType.NAME.to_string (),
            expand = true,
            resizable = true,
            sorter = name_sorter,
        };
        list_view_settings.bind ("name-width", name_column, "fixed-width", DEFAULT);

        var size_factory = new Gtk.SignalListItemFactory ();
        size_factory.setup.connect (setup_size_cell);
        size_factory.bind.connect (CellBase.bind_func);
        size_factory.unbind.connect (CellBase.unbind_func);

        var size_sorter = new Gtk.NumericSorter (new Gtk.PropertyExpression (typeof (FileBase), null, "size"));

        var size_column = new Gtk.ColumnViewColumn (_("Size"), size_factory) {
            id = CellType.SIZE.to_string (),
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

        sorter.bind_property ("primary-sort-column", state, "sort-key", DEFAULT, column_to_cell_type_enum);
        sorter.bind_property ("primary-sort-order", state, "sort-direction", DEFAULT);

        state.notify["sort-key"].connect (update_sorting);
        state.notify["sort-direction"].connect (update_sorting);

        column_view.activate.connect (on_activate);
    }

    private bool column_to_cell_type_enum (Binding binding, Value from_val, ref Value to_val) {
        var column = (Gtk.ColumnViewColumn) from_val.get_object ();

        if (column == null) {
            return false;
        }

        unowned var enum_class = (EnumClass) typeof (CellType).class_peek ();
        unowned var enum_val = enum_class.get_value_by_name (column.id);
        to_val.set_enum (enum_val.value);
        return true;
    }

    private void update_sorting () {
        if (sorter.primary_sort_order == state.sort_direction &&
            sorter.primary_sort_column.id == state.sort_key.to_string ()
        ) {
            return;
        }

        for (int i = 0; i < column_view.columns.get_n_items (); i++) {
            var column = (Gtk.ColumnViewColumn) column_view.columns.get_item (i);
            if (column.id == state.sort_key.to_string ()) {
                column_view.sort_by_column (column, state.sort_direction);
                break;
            }
        }
    }

    private void setup_name_cell (Object obj) {
        var item = (Gtk.ListItem) obj;
        var cell = new FileCell (NAME);
        cell.do_common_setup (item);
        item.child = cell;
    }

    private void setup_size_cell (Object obj) {
        var item = (Gtk.ListItem) obj;
        var cell = new FileCell (SIZE);
        cell.do_common_setup (item);
        item.child = cell;
    }

    private void on_activate (uint position) {
        activate_action_variant (MainWindow.ACTION_PREFIX + MainWindow.ACTION_OPEN, OpenHint.NONE);
    }
}
