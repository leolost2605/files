/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.FileModel : Object, ListModel {
    private Gee.HashSet<string> paths;
    private ListStore store;

    construct {
        paths = new Gee.HashSet<string> ();
        store = new ListStore (typeof (FileBase));
        store.items_changed.connect ((pos, removed, added) => items_changed (pos, removed, added));
    }

    public Object? get_item (uint position) {
        return store.get_item (position);
    }

    public Type get_item_type () {
        return typeof (FileBase);
    }

    public uint get_n_items () {
        return store.get_n_items ();
    }

    public async void append (string path) {
        if (path in paths) {
            return;
        }

        var file = yield FileBase.get_for_path (path);

        if (file == null) {
            warning ("File %s not found.", path);
            return;
        }

        store.append (file);
    }

    public async void remove (string path) {
        if (!(path in paths)) {
            return;
        }

        var file = yield FileBase.get_for_path (path);

        // TODO: THIS NEEDS TO BE OPTIMIZED
        uint position;
        store.find (file, out position);

        store.remove (position);
        paths.remove (path);
    }

    // We only do append multiple with infos otherwise there's no gain in
    public void append_infos (string parent, owned List<FileInfo> infos) {
        FileBase[] additions = new FileBase[infos.length ()];

        int index = 0;
        foreach (var info in infos) {
            var file = FileBase.get_for_info (parent, info);

            if (file == null || file.path in paths) {
                additions.resize (additions.length - 1);
                continue;
            }

            paths.add (file.path);
            additions[index] = file;
            index++;
        }

        store.splice (store.n_items, 0, additions);
    }

    public void remove_all () {
        store.remove_all ();
        paths.clear ();
    }
}
