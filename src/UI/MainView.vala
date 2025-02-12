/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.MainView : Granite.Bin {
    private Directory? _directory;
    public Directory? directory {
        get { return _directory; }
        set {
            if (_directory != null) {
                _directory.queue_unload ();
            }

            _directory = value;

            if (value != null) {
                selection_model.model = value.children;
                value.load ();
            }
        }
    }

    private Gtk.MultiSelection selection_model;

    construct {
        hexpand = true;
        vexpand = true;

        selection_model = new Gtk.MultiSelection (null);

        var list_view = new ListView (selection_model);

        var copy_button = new Gtk.Button.with_label ("Copy");

        var move_button = new Gtk.Button.with_label ("Move");

        var paste_button = new Gtk.Button.with_label ("Paste");

        var main_box = new Gtk.Box (VERTICAL, 6);
        main_box.append (list_view);
        main_box.append (copy_button);
        main_box.append (move_button);
        main_box.append (paste_button);

        child = main_box;

        list_view.file_activated.connect (on_file_activated);

        load.begin ();

        copy_button.clicked.connect (() => copy_selection (false));
        move_button.clicked.connect (() => copy_selection (true));
        paste_button.clicked.connect (paste);
    }

    private void on_file_activated (FileBase file) {
        var dir = file.open ((Gtk.Window) get_root ());

        if (dir != null) {
            directory = dir;
        }
    }

    private async void load () {
        var home_dir = (Directory) yield FileBase.get_for_path (Environment.get_home_dir ());
        directory = home_dir;
    }

    private void copy_selection (bool move) {
        var selection = selection_model.get_selection ();

        File[] files = new File[selection.get_size ()];
        for (int i = 0; i < selection.get_size (); i++) {
            var base_file = (FileBase) selection_model.get_item (selection.get_nth (i));
            files[i] = base_file.file;
            base_file.move_queued = move;
        }

        var file_list = new Gdk.FileList.from_array (files);
        var content_provider = new Gdk.ContentProvider.for_value (file_list);

        root.get_surface ().display.get_clipboard ().set_content (content_provider);
    }

    private async void paste () {
        var clipboard = root.get_surface ().display.get_clipboard ();

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
        string[] paths = {};
        foreach (var file in files) {
            paths += file.get_path ();
        }

        unowned var manager = OperationManager.get_instance ();
        manager.paste_files.begin (paths, directory.path);
    }
}
