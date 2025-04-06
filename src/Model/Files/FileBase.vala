/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

/**
 * The base class for all files. All files are singletons i.e. multiple calls
 * to {@link get_for_uri} will return the same object at any given time.
 * This is the only way to obtain files. It automatically constructs the correct file
 * (directory or document).
 *
 * A FileBase file is backed by a {@link GLib.File}. This file can change (e.g. when it's renamed).
 * Some properties are always valid (like of course the file, uri and also basename) while some
 * are only valid after the file has been loaded with {@link load}.
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

    public signal void changed (File? old_file);

    public Cancellable cancellable { get; construct; }

    private File? _file;
    /**
     * The backing file of #this. It is strongly discouraged to use it directly since
     * it can change during the lifetime of #this.
     * It is only provided for occassions where it's really needed, e.g. when communicating
     * with third parties (dnd, c&p) or doing operations. Instead you should use the properties of #this
     * like {@link basename}, {@link uri}, {@link size}, etc.
     */
    public File file {
        get { return _file; }
        protected construct set {
            if (_file != null) {
                known_files.remove (uri);
            }

            var old_file = _file;
            _file = value;

            uri = _file.get_uri ();
            basename = _file.get_basename ();

            known_files[uri] = this;

            changed (old_file);
        }
    }

    public FileInfo info { protected get; protected construct set; }

    // Properties of the file that are always valid. Note they may change during the lifetime of #this
    public string uri { get; private set; }
    public string basename { get; private set; }

    // Properties of the file that are only valid after it has been loaded

    /**
     * A translated string representing the size of the file. Has to be loaded.
     */
    public string display_size { get; protected set; }
    public int64 size { get; protected set; default = 0; }

    // Misc stuff
    public bool move_queued { get; set; default = false; }

    private bool refreshing = false;
    private uint loaded = 0;
    private uint unload_timeout_id = 0;

    protected FileBase () {}

    construct {
        cancellable = new Cancellable ();
    }

    ~FileBase () {
        cancellable.cancel ();
        known_files.remove (uri);
    }

    protected virtual async void load_internal () { }
    protected virtual async void unload_internal () { }

    public void load () {
        if (unload_timeout_id != 0) {
            Source.remove (unload_timeout_id);
            unload_timeout_id = 0;
        } else if (loaded == 0 && !refreshing) {
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

        if (loaded == 0 && !refreshing) {
            unload_timeout_id = Timeout.add_seconds (5, unload_timeout_func);
        }
    }

    private bool unload_timeout_func () {
        unload_internal.begin ();
        unload_timeout_id = 0;
        return Source.REMOVE;
    }

    public virtual Directory? open (Gtk.Window? parent) {
        return null;
    }

    public async Directory? get_parent () {
        var parent = file.get_parent ();

        if (parent == null) {
            return null;
        }

        var parent_file_base = yield FileBase.get_for_uri (parent.get_uri ());

        if (parent_file_base is Directory) {
            return (Directory) parent_file_base;
        }

        return null;
    }

    public async void refresh () {
        refreshing = true;

        if (unload_timeout_id != 0) {
            Source.remove (unload_timeout_id);
            unload_timeout_id = 0;
            yield unload_internal ();
        } else if (loaded > 0) {
            yield unload_internal ();
        }

        try {
            info = yield file.query_info_async ("standard::*", NONE, Priority.DEFAULT, cancellable);
        } catch (Error e) {
            warning ("Error refreshing file info: %s", e.message);
        }

        if (loaded > 0) {
            yield load_internal ();
        }

        refreshing = false;
    }

    /**
     * This doesn't actually rename the file on disk. For that use
     * {@link OperationManager.rename_files}
     */
    public void rename (File new_file) {
        if (uri == new_file.get_uri ()) {
            return;
        }

        file = new_file;
        refresh.begin ();
    }
}
