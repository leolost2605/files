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
                _directory.disable_unload = false;
                _directory.queue_unload ();
            }

            _directory = value;

            if (value != null) {
                selection_model.model = value.children;
                value.disable_unload = true;
            }
        }
    }

    private Gtk.MultiSelection selection_model;

    construct {
        hexpand = true;
        vexpand = true;

        selection_model = new Gtk.MultiSelection (null);

        var list_view = new ListView (selection_model);

        child = list_view;

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
