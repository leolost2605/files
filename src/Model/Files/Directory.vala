/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.Directory : FileBase {
    public FileModel children { get; construct; }

    private FileMonitor? monitor;

    public Directory (File file, FileInfo info) {
        Object (file: file, info: info);
    }

    construct {
        children = new FileModel ();

        bind_property ("size", this, "display-size", SYNC_CREATE);
        children.bind_property ("n-items", this, "size");
    }

    protected override async void load_internal () {
        cancellable.reset ();

        try {
            monitor = file.monitor_directory (SEND_MOVED, cancellable);
            monitor.changed.connect (on_monitor_changed);
        } catch (Error e) {
            if (!(e is IOError.CANCELLED)) {
                critical ("Error monitoring directory %s: %s", uri, e.message);
            }
        }

        try {
            yield load_initial_children ();
        } catch (Error e) {
            if (!(e is IOError.CANCELLED)) {
                critical ("Error loading initial children for file %s: %s", uri, e.message);
            }
        }
    }

    private async void on_monitor_changed (File file, File? other_file, FileMonitorEvent event_type) {
        switch (event_type) {
            case CREATED:
                children.append.begin (file.get_uri ());
                break;

            case DELETED:
                children.remove.begin (file.get_uri ());
                break;

            case MOVED:
                if (other_file != null && other_file.get_parent ().equal (file.get_parent ())) {
                    var base_file = yield FileBase.get_for_uri (file.get_uri ());
                    base_file.rename (other_file);
                } else {
                    children.remove.begin (file.get_uri ());
                }
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
            children.append_infos (uri, (owned) infos);
        }
    }

    protected override async void unload_internal () {
        monitor.cancel ();
        monitor = null;
        cancellable.cancel ();
        children.remove_all ();
    }

    public override Directory? open (Gtk.Window? parent) {
        return this;
    }
}
