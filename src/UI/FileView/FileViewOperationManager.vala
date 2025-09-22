/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

/**
 * This class is responsible for handling operations for a {@link FileView}.
 * Not to be confused with {@link OperationManager} which is a global object
 * whereas of this one exists for each {@link FileView}.
 * It handles starting operations based on the current selection and makes sure
 * if the operation has resulting files that these get selected if no changes are
 * made between starting the operation and the resulting files coming in.
 */
public class Files.FileViewOperationManager : Object {
    public FileViewState state { get; construct; }
    public Gtk.SelectionModel selection_model { get; construct; }

    private Gee.HashSet<string> select_when_appears;

    public FileViewOperationManager (FileViewState state, Gtk.SelectionModel selection_model) {
        Object (state: state, selection_model: selection_model);
    }

    construct {
        select_when_appears = new Gee.HashSet<string> ();

        selection_model.items_changed.connect_after (on_items_changed);
        selection_model.selection_changed.connect (on_selection_changed);
    }

    private void on_items_changed (uint pos, uint n_removed, uint n_added) {
        for (uint i = pos; i < pos + n_added; i++) {
            var file = (FileBase) selection_model.get_item (i);

            if (file.uri in select_when_appears) {
                selection_model.selection_changed.disconnect (on_selection_changed);
                selection_model.select_item (i, false);
                selection_model.selection_changed.connect (on_selection_changed);

                select_when_appears.remove (file.uri);
            }
        }
    }

    private void on_selection_changed () {
        // If the selection changed for other reasons (e.g. user input)
        // reset any queued "select when appears"
        select_when_appears.clear ();
    }

    private void push_operation (Operation operation) {
        selection_model.unselect_all ();

        select_when_appears.clear ();
        foreach (var info in operation.infos) {
            var uri = operation.calculate_resulting_uri (info);

            if (uri != null) {
                select_when_appears.add (uri);
            }
        }

        OperationManager.get_instance ().push_operation (operation);
    }

    public void copy (Gtk.Root root, bool move) {
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

    public async void paste (Gtk.Root root) {
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

        string[] to_move = {};
        string[] to_copy = {};
        foreach (var file in files) {
            var base_file = yield FileBase.get_for_uri (file.get_uri ());

            if (base_file.move_queued) {
                to_move += base_file.uri;
            } else {
                to_copy += base_file.uri;
            }
        }

        if (to_move.length > 0) {
            push_operation (new MoveOperation (to_move, state.directory.uri));
        }

        if (to_copy.length > 0) {
            push_operation (new CopyOperation (to_copy, state.directory.uri));
        }
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

    public void rename (Gtk.Window window) {
        var selection = selection_model.get_selection ();

        if (selection.get_size () == 1) {
            var base_file = (FileBase) selection_model.get_item (selection.get_nth (0));
            var dialog = new RenameDialog (base_file) {
                transient_for = window,
                modal = true
            };
            dialog.rename_file.connect (on_rename_file);
            dialog.present ();
        } else {
            warning ("Renaming multiple files is not supported yet");
        }
    }

    private void on_rename_file (FileBase file, string new_name) {
        push_operation (new RenameOperation ({ file.uri }, { new_name }));
    }

    public void create_new_folder (Gtk.Window window) {
        var dialog = new NewFolderDialog () {
            transient_for = window,
            modal = true
        };
        dialog.create_folder.connect (on_create_folder);
        dialog.present ();
    }

    private void on_create_folder (string name) {
        var folder = state.directory.file.get_child (name);
        push_operation (new MakeDirectoryOperation ({ folder.get_uri () }));
    }

    public void open (Gtk.Window window, OpenHint hint) {
        var selection = selection_model.get_selection ();

        //TODO: Multiple directories selected will cause us to open only the last one.
        for (int i = 0; i < selection.get_size (); i++) {
            var file = (FileBase) selection_model.get_item (selection.get_nth (i));
            var dir = file.open (window, hint == CHOOSE);

            if (dir != null) {
                state.directory = dir;
            }
        }
    }
}
