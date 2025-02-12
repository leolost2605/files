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
                action_handler.directory = null;
            }

            _directory = value;

            if (value != null) {
                selection_model.model = value.children;
                value.load ();
                action_handler.directory = value;
            }
        }
    }

    private Gtk.MultiSelection selection_model;
    private ActionHandler action_handler;

    construct {
        hexpand = true;
        vexpand = true;

        selection_model = new Gtk.MultiSelection (null);

        action_handler = new ActionHandler (selection_model, this);
        insert_action_group (ActionHandler.ACTION_GROUP_PREFIX, action_handler.action_group);

        var list_view = new ListView (selection_model);

        var copy_button = new Gtk.Button.with_label ("Copy") {
            action_name = ActionHandler.ACTION_PREFIX + ActionHandler.ACTION_COPY,
        };

        var move_button = new Gtk.Button.with_label ("Move") {
            action_name = ActionHandler.ACTION_PREFIX + ActionHandler.ACTION_CUT,
        };

        var paste_button = new Gtk.Button.with_label ("Paste") {
            action_name = ActionHandler.ACTION_PREFIX + ActionHandler.ACTION_PASTE,
        };

        var main_box = new Gtk.Box (VERTICAL, 6);
        main_box.append (list_view);
        main_box.append (copy_button);
        main_box.append (move_button);
        main_box.append (paste_button);

        child = main_box;

        list_view.file_activated.connect (on_file_activated);

        load.begin ();
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
}
