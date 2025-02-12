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
        var path = Path.build_filename (parent, info.get_name ());

        if (path in known_files) {
            return known_files[path];
        }

        var file = File.new_for_path (path);

        if (info.get_file_type () == DIRECTORY) {
            return new Directory (file, info);
        } else {
            return new Document (file, info);
        }
    }

    public static async FileBase? get_for_path (string path) {
        if (path in known_files) {
            return known_files[path];
        }

        var file = File.new_for_path (path);

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

    public string path { get; construct; }
    public string basename { get; private set; }

    public File file { protected get; construct; }
    public FileInfo info { protected get; construct; }
    public Cancellable cancellable { protected get; construct; }

    protected FileBase () {}

    construct {
        cancellable = new Cancellable ();

        path = file.get_path ();
        basename = file.get_basename ();

        known_files[path] = this;
    }

    ~FileBase () {
        cancellable.cancel ();
        known_files.remove (path);
    }

    public virtual void load () { }

    public virtual void queue_unload () { }

    public virtual Directory? open (Gtk.Window? parent) {
        return null;
    }
}
