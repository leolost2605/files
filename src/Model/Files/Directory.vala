/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.Directory : FileBase {
    public FileModel children { get; construct; }

    private bool _disable_unload = false; // E.g. while it's visible
    public bool disable_unload {
        get { return _disable_unload; }
        set {
            _disable_unload = value;
            if (value) {
                load ();

                if (unload_timeout_id != 0) {
                    GLib.Source.remove (unload_timeout_id);
                    unload_timeout_id = 0;
                }
            }
        }
    }

    private FileMonitor? monitor;

    private uint unload_timeout_id = 0;

    public Directory (File file, FileInfo info) {
        Object (file: file, info: info);
    }

    construct {
        children = new FileModel ();
    }

    public override void load () {
        load_internal.begin ();
    }

    private async void load_internal () {
        if (unload_timeout_id != 0) {
            GLib.Source.remove (unload_timeout_id);
            unload_timeout_id = 0;
        }

        cancellable.reset ();

        try {
            monitor = file.monitor_directory (SEND_MOVED, cancellable);
            monitor.changed.connect (on_monitor_changed);
        } catch (Error e) {
            if (!(e is IOError.CANCELLED)) {
                critical ("Error monitoring directory %s: %s", path, e.message);
            }
        }

        try {
            yield load_initial_children ();
        } catch (Error e) {
            if (!(e is IOError.CANCELLED)) {
                critical ("Error loading initial children for file %s: %s", path, e.message);
            }
        }
    }

    private void on_monitor_changed (File file, File? other_file, FileMonitorEvent event_type) {
        switch (event_type) {
            case CREATED:
                children.append.begin (file.get_path ());
                break;

            case DELETED:
                children.remove.begin (file.get_path ());
                break;

            default:
                break;
        }
    }

    private async void load_initial_children () throws Error {
        var enumerator = yield file.enumerate_children_async ("standard::*", NONE, Priority.DEFAULT, cancellable);

        for (List<FileInfo> infos = yield enumerator.next_files_async (50, Priority.DEFAULT, cancellable);
             infos.length () > 0;
             infos = yield enumerator.next_files_async (50, Priority.DEFAULT, cancellable)
        ) {
            children.append_infos (path, (owned) infos);
        }
    }

    public override void queue_unload () {
        if (unload_timeout_id != 0 || disable_unload) {
            return;
        }

        unload_timeout_id = Timeout.add_seconds (5, unload);
    }

    private bool unload () {
        unload_timeout_id = 0;

        monitor.cancel ();
        monitor = null;
        cancellable.cancel ();
        children.remove_all ();

        return Source.REMOVE;
    }

    public override Directory? open (Gtk.Window? parent) {
        return this;
    }
}
