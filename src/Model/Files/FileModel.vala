/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.FileModel : Object, ListModel {
    public uint n_items { get; protected set; }

    private Gee.HashSet<string> uris;
    private ListStore store;

    construct {
        uris = new Gee.HashSet<string> ();
        store = new ListStore (typeof (FileBase));
        store.items_changed.connect ((pos, removed, added) => items_changed (pos, removed, added));

        store.bind_property ("n-items", this, "n-items");
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

    public async void append (string uri) {
        if (uri in uris) {
            return;
        }

        var file = yield FileBase.get_for_uri (uri);

        if (file == null) {
            warning ("File %s not found.", uri);
            return;
        }

        uris.add (file.uri);
        store.append (file);
    }

    public async void remove (string uri) {
        if (!(uri in uris)) {
            return;
        }

        var file = yield FileBase.get_for_uri (uri);

        // TODO: THIS NEEDS TO BE OPTIMIZED
        uint position;
        store.find (file, out position);

        store.remove (position);
        uris.remove (uri);
    }

    // We only do append multiple with infos otherwise there's no gain in
    public void append_infos (string parent, owned List<FileInfo> infos) {
        FileBase[] additions = new FileBase[infos.length ()];

        int index = 0;
        foreach (var info in infos) {
            var file = FileBase.get_for_info (parent, info);

            if (file == null || file.uri in uris) {
                additions.resize (additions.length - 1);
                continue;
            }

            uris.add (file.uri);
            additions[index] = file;
            index++;
        }

        store.splice (store.n_items, 0, additions);
    }

    public async void rename (string old_uri, string new_uri) {
        if (!(old_uri in uris)) {
            return;
        }

        uris.remove (old_uri);
        uris.add (new_uri);

        var old_file = yield FileBase.get_for_uri (old_uri);
        var new_file = yield FileBase.get_for_uri (new_uri);

        uint position;
        store.find (old_file, out position);

        store.splice (position, 1, { new_file });
    }

    public void remove_all () {
        store.remove_all ();
        uris.clear ();
    }
}
