/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.MoveOperation : ConflictableOperation {
    public string[] source_paths { get; construct; }
    public string destination_path { get; construct; }

    public MoveOperation (string[] source_paths, string destination_path) {
        Object (source_paths: source_paths, destination_path: destination_path);
    }

    public override void start () {
        move.begin ();
    }

    private async void move () {
        foreach (var path in source_paths) {
            var source = File.new_for_path (path);
            var destination = File.new_build_filename (destination_path, source.get_basename ());

            try {
                yield run_conflict_op (source, destination, MOVE);
            } catch (Error e) {
                report_error ("Failed to move file %s to %s: %s".printf (source.get_path (), destination.get_path (), e.message));
            }
        }

        done ();
    }
}
