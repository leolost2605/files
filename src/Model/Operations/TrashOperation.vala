/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.TrashOperation : Operation {
    public string[] source_paths { get; construct; }

    public TrashOperation (string[] source_paths) {
        Object (source_paths: source_paths);
    }

    public override void start () {
        trash.begin ();
    }

    private void trash () {
        foreach (var path in source_paths) {
            var source = File.new_for_path (path);

            try {
                yield source.trash_async (Priority.DEFAULT, cancellable);
            } catch (Error e) {
                report_error ("Failed to trash file %s: %s".printf (source.get_path (), e.message));
            }
        }

        done ();
    }
}
