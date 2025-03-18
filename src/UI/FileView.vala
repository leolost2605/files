/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

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
                selection_model.model = value.children;
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
        }
    }

    public bool can_go_back { get { return current_index > 0; } }
    public bool can_go_forward { get { return current_index < history.size - 1; } }

    private Gee.ArrayList<Directory> history;
    private int current_index = -1;

    private Gtk.MultiSelection selection_model;

    construct {
        history = new Gee.ArrayList<Directory> ();
        selection_model = new Gtk.MultiSelection (null);

        var list_view = new ListView (selection_model);

        var copy_button = new Gtk.Button.with_label ("Copy") {
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_COPY,
        };

        var move_button = new Gtk.Button.with_label ("Move") {
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_CUT,
        };

        var paste_button = new Gtk.Button.with_label ("Paste") {
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_PASTE,
        };

        var main_box = new Gtk.Box (VERTICAL, 6);
        main_box.append (list_view);
        main_box.append (copy_button);
        main_box.append (move_button);
        main_box.append (paste_button);

        hexpand = true;
        vexpand = true;
        child = main_box;

        map.connect (on_map);

        list_view.file_activated.connect (on_file_activated);
    }

    private void on_map () {
        if (directory != null) {
            activate_action_variant (MainWindow.ACTION_PREFIX + MainWindow.ACTION_GOTO, directory.uri);
        }
    }

    private void on_file_activated (FileBase file) {
        var dir = file.open ((Gtk.Window) get_root ());

        if (dir != null) {
            activate_action_variant (MainWindow.ACTION_PREFIX + MainWindow.ACTION_GOTO, dir.uri);
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
}
