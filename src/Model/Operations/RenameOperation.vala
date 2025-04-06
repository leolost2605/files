/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

 public class Files.RenameOperation : ConflictableOperation {
    public string[] source_uris { get; construct; }
    public string[] new_names { get; construct; }

    public RenameOperation (string[] source_uris, string[] new_names) {
        Object (source_uris: source_uris, new_names: new_names);
    }

    public override void start () {
        if (source_uris.length != new_names.length) {
            report_error ("Source URIs and new names must have the same length. This is a programming error and should be reported.");
            return;
        }

        rename.begin ();
    }

    private async void rename () {
        for (int i = 0; i < source_uris.length; i++) {
            var source = File.new_for_uri (source_uris[i]);
            var new_name = new_names[i];

            try {
                yield source.set_display_name_async (new_name, Priority.DEFAULT, cancellable);
            } catch (Error e) {
                report_error ("Failed to rename file %s to %s: %s".printf (source.get_uri (), new_name, e.message));
            }
        }

        done ();
    }
}
