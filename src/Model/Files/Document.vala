/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.Document : FileBase {
    public Document (File file, FileInfo info) {
        Object (file: file, info: info);
    }

    protected override async void load_internal () {
        size = info.get_size ();
        display_size = GLib.format_size (size, DEFAULT);
    }

    public override Directory? open (Gtk.Window? parent, bool allow_choose) {
        launch.begin (parent, allow_choose);
        return null;
    }

    private async void launch (Gtk.Window? parent, bool allow_choose) {
        var file_launcher = new Gtk.FileLauncher (file) {
            always_ask = allow_choose
        };

        try {
            yield file_launcher.launch (parent, null);
        } catch (Error e) {
            critical ("Failed to open file %s: %s", uri, e.message);
        }
    }
}
