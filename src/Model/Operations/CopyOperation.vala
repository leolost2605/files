/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.CopyOperation : ConflictableOperation {
    public string[] source_uris { get; construct; }
    public string destination_uri { get; construct; }

    public CopyOperation (string[] source_uris, string destination_uri) {
        Object (source_uris: source_uris, destination_uri: destination_uri);
    }

    public override void start () {
        copy.begin ();
    }

    private async void copy () {
        foreach (var uri in source_uris) {
            var source = File.new_for_uri (uri);
            FileInfo source_info;
            try {
                source_info = yield source.query_info_async ("standard::*", NONE, Priority.DEFAULT, cancellable);
            } catch (Error e) {
                report_error ("Failed to query info for file %s, skipping copy: %s".printf (uri, e.message));
                continue;
            }
            var destination = File.new_build_filename (destination_uri, source.get_basename ());

            try {
                yield copy_recursive (source, source_info, destination);
            } catch (Error e) {
                report_error ("Failed to copy file %s to %s: %s".printf (uri, destination.get_uri (), e.message));
            }
        }

        done ();
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
                    var destination_child = File.new_build_filename (destination.get_uri (), info.get_name ());
                    yield copy_recursive (source_child, info, destination_child);
                }
            }
        } else {
            yield run_conflict_op (source, destination, COPY);
        }
    }
}
