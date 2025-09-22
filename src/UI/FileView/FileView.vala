/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public enum Files.OpenHint {
    NONE,
    CHOOSE,
    NEW_TAB,
    NEW_WINDOW,
}

public enum Files.CellType {
    NAME,
    SIZE
}

public enum Files.ViewType {
    LIST,
    GRID
}

public class Files.FileView : Granite.Bin {
    public FileViewState state { get; construct; }

    private Gtk.MultiSelection selection_model;
    private FileViewOperationManager operation_manager;

    private Gtk.PopoverMenu context_menu;

    public FileView (FileViewState state) {
        Object (state: state);
    }

    construct {
        var filter_model = new Gtk.FilterListModel (null, null);
        state.bind_property ("directory", filter_model, "model", SYNC_CREATE, (binding, from_val, ref to_val) => {
            var dir = (Directory) from_val.get_object ();
            to_val.set_object (dir?.children);
            return true;
        });

        var sort_model = new Gtk.SortListModel (filter_model, null);
        selection_model = new Gtk.MultiSelection (sort_model);

        operation_manager = new FileViewOperationManager (state, selection_model);

        // The ListView is our "master" view for sorting since it handles it via the column view
        Gtk.Sorter sorter;
        var list_view = new ListView (state, selection_model, out sorter);
        sort_model.sorter = sorter;

        var grid_view = new GridView (selection_model);

        var stack = new Gtk.Stack ();
        stack.add_named (list_view, ViewType.LIST.to_string ());
        stack.add_named (grid_view, ViewType.GRID.to_string ());
        state.bind_property ("view-type", stack, "visible-child-name", SYNC_CREATE);

        hexpand = true;
        vexpand = true;
        child = stack;

        settings.bind_with_mapping ("show-hidden-files", filter_model, "filter", GET, (val, variant, user_data) => {
            if ((bool) variant) {
                val.set_object (null);
            } else {
                val.set_object (new Gtk.BoolFilter (new Gtk.PropertyExpression (typeof (FileBase), null, "hidden")) { invert = true });
            }
            return true;
        }, () => {}, null, null);

        settings.bind_with_mapping ("sort-folders-before-files", sort_model, "section-sorter", GET, (val, variant, user_data) => {
            if ((bool) variant) {
                val.set_object (new Gtk.CustomSorter ((a, b) => {
                    if (a is Directory && b is Directory || a is Document && b is Document) {
                        return 0;
                    } else if (a is Directory) {
                        return -1;
                    } else {
                        return 1;
                    }
                }));
            } else {
                val.set_object (null);
            }
            return true;
        }, () => {}, null, null);

        var gesture_click_middle = new Gtk.GestureClick () {
            button = Gdk.BUTTON_MIDDLE
        };
        add_controller (gesture_click_middle);
        gesture_click_middle.pressed.connect ((n_press, x, y) => on_middle_click (x, y));

        context_menu = new Gtk.PopoverMenu.from_model (new Menu ()) {
            has_arrow = false,
            halign = START
        };
        context_menu.set_parent (this);

        var gesture_click = new Gtk.GestureClick () {
            button = Gdk.BUTTON_SECONDARY
        };
        add_controller (gesture_click);
        gesture_click.pressed.connect ((n_press, x, y) => on_secondary_click (x, y));

        var long_press = new Gtk.GestureLongPress () {
            touch_only = true,
        };
        add_controller (long_press);
        long_press.pressed.connect (on_secondary_click);
    }

    public void copy (bool move) {
        operation_manager.copy (root, move);
    }

    public void paste () {
        operation_manager.paste.begin (root);
    }

    public void trash () {
        operation_manager.trash ();
    }

    public void rename () {
        operation_manager.rename ((Gtk.Window) root);
    }

    public void create_new_folder () {
        operation_manager.create_new_folder ((Gtk.Window) root);
    }

    public void open (OpenHint hint) {
        operation_manager.open ((Gtk.Window) root, hint);
    }

    private void on_middle_click (double x, double y) {
        var cell = (CellBase) pick (x, y, DEFAULT).get_ancestor (typeof (CellBase));

        if (cell == null) {
            return;
        }

        var file = (FileBase) selection_model.get_item (cell.position);
        activate_action_variant (
            MainWindow.ACTION_PREFIX + MainWindow.ACTION_NEW_TAB,
            new Variant.maybe (null, new Variant.string (file.uri))
        );
    }

    private void on_secondary_click (double x, double y) {
        var cell = (CellBase) pick (x, y, DEFAULT).get_ancestor (typeof (CellBase));

        if (cell == null) {
            selection_model.unselect_all ();
        } else if (!(cell.position in selection_model.get_selection ())) {
            selection_model.select_item (cell.position, true);
        }

        context_menu.menu_model = build_menu ();
        context_menu.pointing_to = { (int) x, (int) y, 0, 0 };
        context_menu.popup ();
    }

    private Menu build_menu () {
        var selection_size = selection_model.get_selection ().get_size ();

        var menu = new Menu ();

        menu.append_section (null, build_new_section (selection_size));
        menu.append_section (null, build_open_section (selection_size));
        menu.append_section (null, build_edit_section (selection_size));

        if (selection_size > 0) {
            var destructive_section = new Menu ();
            destructive_section.append (_("Move to Trash"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_TRASH);

            menu.append_section (null, destructive_section);
        }

        return menu;
    }

    private Menu build_new_section (uint64 selection_size) {
        if (selection_size > 0) {
            return new Menu ();
        }

        var new_section = new Menu ();

        new_section.append (_("New Folder"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_NEW_FOLDER);

        return new_section;
    }

    private Menu build_open_section (uint64 selection_size) {
        if (selection_size != 1) {
            return new Menu ();
        }

        var selection = selection_model.get_selection ();
        var item = (FileBase) selection_model.get_item (selection.get_nth (0));

        var open_section = new Menu ();

        if (item is Document) {
            open_section.append (
                _("Open with <Insert default here>"),
                Action.print_detailed_name (MainWindow.ACTION_PREFIX + MainWindow.ACTION_OPEN, OpenHint.NONE)
            );
            open_section.append (
                _("Open with…"),
                Action.print_detailed_name (MainWindow.ACTION_PREFIX + MainWindow.ACTION_OPEN, OpenHint.CHOOSE)
            );
        } else {
            open_section.append (
                _("Open"),
                Action.print_detailed_name (MainWindow.ACTION_PREFIX + MainWindow.ACTION_OPEN, OpenHint.NONE)
            );
            open_section.append (
                _("Open in New Tab"),
                Action.print_detailed_name (
                    MainWindow.ACTION_PREFIX + MainWindow.ACTION_NEW_TAB,
                    new Variant.maybe (null, new Variant.string (item.uri))
                )
            );
        }

        return open_section;
    }

    private Menu build_edit_section (uint64 selection_size) {
        var edit_section = new Menu ();

        if (selection_size > 0) {
            edit_section.append (_("Copy"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_COPY);
            edit_section.append (_("Cut"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_CUT);
            edit_section.append (_("Rename"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_RENAME);
        } else {
            edit_section.append (_("Paste"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_PASTE);
        }

        return edit_section;
    }
}
