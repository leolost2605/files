/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.TrashOperation : Operation {
    public string[] source_uris { get; construct; }

    public TrashOperation (string[] source_uris) {
        Object (source_uris: source_uris);
    }

    public override void start () {
        trash.begin ();
    }

    private async void trash () {
        foreach (var uri in source_uris) {
            var source = File.new_for_uri (uri);

            try {
                yield source.trash_async (Priority.DEFAULT, cancellable);
            } catch (Error e) {
                report_error ("Failed to trash file %s: %s".printf (source.get_uri (), e.message));
            }
        }

        done ();
    }
}
