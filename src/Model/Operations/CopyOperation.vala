/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.CopyOperation : ConflictableOperation {
    public string[] source_paths { get; construct; }
    public string destination_path { get; construct; }

    public CopyOperation (string[] source_paths, string destination_path) {
        Object (source_paths: source_paths, destination_path: destination_path);
    }

    public override void start () {
        copy.begin ();
    }

    private async void copy () {
        foreach (var path in source_paths) {
            var source = File.new_for_path (path);
            FileInfo source_info;
            try {
                source_info = yield source.query_info_async ("standard::*", NONE, Priority.DEFAULT, cancellable);
            } catch (Error e) {
                report_error ("Failed to query info for file %s, skipping copy: %s".printf (path, e.message));
                continue;
            }
            var destination = File.new_build_filename (destination_path, source.get_basename ());

            try {
                yield copy_recursive (source, source_info, destination);
            } catch (Error e) {
                report_error ("Failed to copy file %s to %s: %s".printf (path, destination.get_path (), e.message));
            }
        }
    }

    private async void copy_recursive (File source, FileInfo source_info, File destination) throws Error {
        if (source_info.get_file_type () == DIRECTORY) {
            yield destination.make_directory_async (Priority.DEFAULT, cancellable);

            // todo copy attributes

            var enumerator = yield source.enumerate_children_async ("standard::*", NONE, Priority.DEFAULT, cancellable);

            for (List<FileInfo> infos = yield enumerator.next_files_async (50, Priority.DEFAULT, cancellable);
                 infos.length () > 0;
                 infos = yield enumerator.next_files_async (50, Priority.DEFAULT, cancellable)
            ) {
                foreach (var info in infos) {
                    var source_child = source.get_child (info.get_name ());
                    var destination_child = File.new_build_filename (destination.get_path (), info.get_name ());
                    yield copy_recursive (source_child, info, destination_child);
                }
            }
        } else {
            yield run_conflict_op (source, destination, COPY);
        }
    }
}
