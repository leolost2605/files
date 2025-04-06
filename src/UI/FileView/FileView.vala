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
    SIZE,
}

public enum Files.ViewType {
    LIST,
    GRID;

    public string to_string () {
        switch (this) {
            case LIST:
                return "list";

            case GRID:
                return "grid";

            default:
                warning ("Unknown view type: %d", (int) this);
                return "list";
        }
    }

    public static ViewType from_string (string str) {
        switch (str) {
            case "list":
                return LIST;

            case "grid":
                return GRID;
        }

        warning ("Unknown view type: %s", str);
        return LIST;
    }
}

public class Files.FileView : Granite.Bin {
    private Directory? _directory;
    public Directory? directory {
        get { return _directory; }
        set {
            if (_directory == value) {
                return;
            }

            if (_directory != null) {
                _directory.queue_unload ();
            }

            _directory = value;

            if (history.size - 1 > current_index && history.get (current_index + 1) != value) {
                for (int i = current_index + 1; i < history.size; i++) {
                    history.remove_at (i);
                }
            }

            if (value != null) {
                filter_model.model = value.children;
                value.load ();

                if (current_index > 0 && value == history.get (current_index - 1)) {
                    current_index--;
                } else if (history.size - 1 > current_index && value == history.get (current_index + 1)) {
                    current_index++;
                } else {
                    history.add (value);
                    current_index++;
                }
            } else {
                //todo show placeholder
            }

            sync_history_actions ();
        }
    }

    public ViewType view_type {
        get { return ViewType.from_string (stack.visible_child_name); }
        set { stack.visible_child_name = value.to_string (); }
    }

    private Gee.ArrayList<Directory> history;
    private int current_index = -1;

    private Gtk.FilterListModel filter_model;
    private Gtk.MultiSelection selection_model;

    private ListView list_view;

    private Gtk.Stack stack;

    private Gtk.PopoverMenu context_menu;

    construct {
        history = new Gee.ArrayList<Directory> ();

        filter_model = new Gtk.FilterListModel (null, null);
        var sort_model = new Gtk.SortListModel (filter_model, null);
        selection_model = new Gtk.MultiSelection (sort_model);

        // The ListView is our "master" view for sorting since it handles it via the column view
        Gtk.Sorter sorter;
        list_view = new ListView (selection_model, out sorter);
        sort_model.sorter = sorter;

        var grid_view = new GridView (selection_model);

        stack = new Gtk.Stack ();
        stack.add_named (list_view, ViewType.LIST.to_string ());
        stack.add_named (grid_view, ViewType.GRID.to_string ());

        hexpand = true;
        vexpand = true;
        child = stack;

        map.connect (on_map);
        unmap.connect (on_unmap);

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
                    if (a is Directory && b is Directory) {
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

        var long_press = new Gtk.GestureLongPress ();
        add_controller (long_press);
        long_press.pressed.connect (on_secondary_click);
    }

    private void on_map () {
        /* We have to activate the actions after we are mapped because mapping means we are now the visible tab.
         * So we have to make sure that the header bar is up to date with our values
         */
        if (directory != null) {
            activate_action_variant (MainWindow.ACTION_PREFIX + MainWindow.ACTION_GOTO, directory.uri);
        }

        var action_group = (ActionGroup) get_ancestor (typeof (ActionGroup));

        if (action_group != null) {
            action_group.change_action_state (MainWindow.ACTION_VIEW_TYPE, (int) view_type);
        }

        list_view.start_listen ();
        sync_history_actions ();
    }

    private void on_unmap () {
        list_view.end_listen ();
    }

    private void sync_history_actions () {
        var main_window = (MainWindow) get_ancestor (typeof (MainWindow));

        if (main_window != null) {
            var back = (SimpleAction) main_window.lookup_action (MainWindow.ACTION_BACK);
            var forward = (SimpleAction) main_window.lookup_action (MainWindow.ACTION_FORWARD);

            back.set_enabled (current_index > 0);
            forward.set_enabled (current_index < history.size - 1);
        }
    }

    public void back () {
        if (current_index == 0) {
            return;
        }

        activate_action_variant (MainWindow.ACTION_PREFIX + MainWindow.ACTION_GOTO, history.get (current_index - 1).uri);
    }

    public void forward () {
        if (current_index == history.size - 1) {
            return;
        }

        activate_action_variant (MainWindow.ACTION_PREFIX + MainWindow.ACTION_GOTO, history.get (current_index + 1).uri);
    }

    public void copy (bool move) {
        var selection = selection_model.get_selection ();

        File[] files = new File[selection.get_size ()];
        for (int i = 0; i < selection.get_size (); i++) {
            var base_file = (FileBase) selection_model.get_item (selection.get_nth (i));
            files[i] = base_file.file;
            base_file.move_queued = move;
        }

        var file_list = new Gdk.FileList.from_array (files);
        var content_provider = new Gdk.ContentProvider.for_value (file_list);

        parent.root.get_surface ().display.get_clipboard ().set_content (content_provider);
    }

    public async void paste () {
        var clipboard = parent.root.get_surface ().display.get_clipboard ();

        Gdk.FileList file_list;
        try {
            var val = yield clipboard.read_value_async (typeof (Gdk.FileList), Priority.DEFAULT, null);

            if (val == null) {
                return;
            }

            file_list = (Gdk.FileList) val.get_boxed ();
        } catch (Error e) {
            warning ("Failed to read clipboard: %s", e.message);
            return;
        }

        var files = file_list.get_files ();
        string[] uris = {};
        foreach (var file in files) {
            uris += file.get_uri ();
        }

        unowned var manager = OperationManager.get_instance ();
        manager.paste_files.begin (uris, directory.uri);
    }

    public void trash () {
        var selection = selection_model.get_selection ();

        string[] files = new string[selection.get_size ()];
        for (int i = 0; i < selection.get_size (); i++) {
            var base_file = (FileBase) selection_model.get_item (selection.get_nth (i));
            files[i] = base_file.uri;
        }

        OperationManager.get_instance ().push_operation (new TrashOperation (files));
    }

    public void rename () {
        var selection = selection_model.get_selection ();

        if (selection.get_size () == 1) {
            var base_file = (FileBase) selection_model.get_item (selection.get_nth (0));
            new RenameDialog (base_file).present ();
        } else {
            warning ("Renaming multiple files is not supported yet");
        }
    }

    public void open (OpenHint hint) {
        var selection = selection_model.get_selection ();

        //TODO: Multiple directories selected will cause us to open only the last one.
        for (int i = 0; i < selection.get_size (); i++) {
            var file = (FileBase) selection_model.get_item (selection.get_nth (i));
            var dir = file.open ((Gtk.Window) get_root (), hint == CHOOSE);

            if (dir != null) {
                activate_action_variant (MainWindow.ACTION_PREFIX + MainWindow.ACTION_GOTO, dir.uri);
            }
        }
    }

    private void on_secondary_click (double x, double y) {
        context_menu.menu_model = build_menu ();
        context_menu.pointing_to = { (int) x, (int) y, 0, 0 };
        context_menu.popup ();
    }

    private Menu build_menu () {
        var selection = selection_model.get_selection ();

        var menu = new Menu ();

        if (selection.get_size () == 1) {
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
            }

            menu.append_section (null, open_section);
        }

        var edit_section = new Menu ();
        edit_section.append (_("Copy"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_COPY);
        edit_section.append (_("Cut"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_CUT);
        edit_section.append (_("Rename"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_RENAME);

        menu.append_section (null, edit_section);

        var destructive_action = new Menu ();
        destructive_action.append (_("Move to Trash"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_TRASH);

        menu.append_section (null, destructive_action);

        return menu;
    }
}
