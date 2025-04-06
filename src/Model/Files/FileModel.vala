/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.FileModel : Object, ListModel {
    private Gee.HashSet<string> uris;
    private ListStore store;

    construct {
        uris = new Gee.HashSet<string> ();
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

    /**
     * Add to uris and connect changed.
     * To allow performance optimization (splice) we don't add it to the store here.
     */
    private void register_file (FileBase file) {
        uris.add (file.uri);
        file.changed.connect (on_changed);
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

        register_file (file);
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
        file.changed.disconnect (on_changed);
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

            register_file (file);
            additions[index] = file;
            index++;
        }

        store.splice (store.n_items, 0, additions);
    }

    public void remove_all () {
        store.remove_all ();
        uris.clear ();
    }

    private void on_changed (FileBase file, File? old_file) {
        if (file.uri != old_file.get_uri ()) {
            uris.remove (old_file.get_uri ());
            uris.add (file.uri);
        }

        uint pos;
        if (store.find (file, out pos)) {
            items_changed (pos, 1, 1);
        }
    }
}
