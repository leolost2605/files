/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.ActionHandler : Object {
    public const string ACTION_GROUP_PREFIX = "main-view";
    public const string ACTION_PREFIX = ACTION_GROUP_PREFIX + ".";
    public const string ACTION_COPY = "copy";
    public const string ACTION_CUT = "cut";
    public const string ACTION_PASTE = "paste";
    public const string ACTION_TRASH = "trash";

    private const ActionEntry[] ACTION_ENTRIES = {
        {ACTION_COPY, on_copy },
        {ACTION_CUT, on_cut },
        {ACTION_PASTE, on_paste },
        {ACTION_TRASH, on_trash },
    };

    public Gtk.MultiSelection selection_model { get; construct; }
    public Gtk.Widget parent { get; construct; }

    public Directory? directory { get; set; }

    public SimpleActionGroup action_group { get; construct; }

    public ActionHandler (Gtk.MultiSelection selection_model, Gtk.Widget parent) {
        Object (selection_model: selection_model, parent: parent);
    }

    construct {
        action_group = new SimpleActionGroup ();
        action_group.add_action_entries (ACTION_ENTRIES, this);
    }

    private void on_copy () {
        copy (false);
    }

    private void on_cut () {
        copy (true);
    }

    private void copy (bool move) {
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

    private void on_paste () {
        paste.begin ();
    }

    private async void paste () {
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
        string[] paths = {};
        foreach (var file in files) {
            paths += file.get_path ();
        }

        unowned var manager = OperationManager.get_instance ();
        manager.paste_files.begin (paths, directory.path);
    }

    private void on_trash () {
        var selection = selection_model.get_selection ();

        string[] files = new string[selection.get_size ()];
        for (int i = 0; i < selection.get_size (); i++) {
            var base_file = (FileBase) selection_model.get_item (selection.get_nth (i));
            files[i] = base_file.path;
        }

        OperationManager.get_instance ().push_operation (new TrashOperation (files));
    }
}
