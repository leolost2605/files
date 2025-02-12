/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.Document : FileBase {
    public Document (File file, FileInfo info) {
        Object (file: file, info: info);
    }

    public override Directory? open (Gtk.Window? parent) {
        launch.begin (parent);
        return null;
    }

    private async void launch (Gtk.Window? parent) {
        var file_launcher = new Gtk.FileLauncher (file) {
            always_ask = false
        };

        try {
            yield file_launcher.launch (parent, null);
        } catch (Error e) {
            critical ("Failed to open file %s: %s", path, e.message);
        }
    }
}
