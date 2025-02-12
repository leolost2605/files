/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public abstract class Files.FileBase : Object {
    private static HashTable<string, unowned FileBase> known_files;

    public static void init () {
        known_files = new HashTable<string, unowned FileBase> (str_hash, str_equal);
    }

    public static FileBase? get_for_info (string parent, FileInfo info) {
        File parent_file = File.new_for_uri (parent);

        var file = parent_file.get_child (info.get_name ());

        if (file.get_uri () in known_files) {
            return known_files[file.get_uri ()];
        }

        if (info.get_file_type () == DIRECTORY) {
            return new Directory (file, info);
        } else {
            return new Document (file, info);
        }
    }

    public static async FileBase? get_for_path (string path) {
        try {
            var uri = Filename.to_uri (path, null);
            return yield get_for_uri (uri);
        } catch (Error e) {
            warning ("Error converting path to URI: %s", e.message);
        }

        return null;
    }

    public static async FileBase? get_for_uri (string uri) {
        if (uri in known_files) {
            return known_files[uri];
        }

        var file = File.new_for_uri (uri);

        FileInfo info;
        try {
            info = yield file.query_info_async ("standard::*", NONE, Priority.DEFAULT, null);
        } catch (Error e) {
            warning ("Error querying file info: %s", e.message);
            return null;
        }

        if (info.get_file_type () == DIRECTORY) {
            return new Directory (file, info);
        } else {
            return new Document (file, info);
        }
    }

    public string uri { get; construct; }
    public string basename { get; private set; }

    public bool move_queued { get; set; default = false; }

    public File file { get; construct; }
    public FileInfo info { protected get; construct; }
    public Cancellable cancellable { protected get; construct; }

    private uint loaded = 0;
    private uint unload_timeout_id = 0;

    protected FileBase () {}

    construct {
        cancellable = new Cancellable ();

        uri = file.get_uri ();
        basename = file.get_basename ();

        known_files[uri] = this;
    }

    ~FileBase () {
        cancellable.cancel ();
        known_files.remove (uri);
    }

    public void load () {
        if (unload_timeout_id != 0) {
            Source.remove (unload_timeout_id);
            unload_timeout_id = 0;
        } else if (loaded == 0) {
            load_internal.begin ();
        }

        loaded++;
    }

    public void queue_unload () {
        if (loaded == 0 || unload_timeout_id != 0) {
            critical ("Unload called on unloaded file %s so to often", uri);
            return;
        }

        loaded--;

        if (loaded == 0) {
            unload_timeout_id = Timeout.add_seconds (5, unload_timeout_func);
        }
    }

    private bool unload_timeout_func () {
        unload_internal.begin ();
        unload_timeout_id = 0;
        return Source.REMOVE;
    }

    protected virtual async void load_internal () { }
    protected virtual async void unload_internal () { }

    public virtual Directory? open (Gtk.Window? parent) {
        return null;
    }
}
