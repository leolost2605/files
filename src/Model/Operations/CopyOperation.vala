/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.CopyOperation : ConflictableOperation {
    public CopyOperation (string[] source_uris, string destination_uri) {
        var infos = new Gee.ArrayList<OperationInfo> ();
        for (int i = 0; i < source_uris.length; i++) {
            infos.add (new OperationInfo (source_uris[i], destination_uri));
        }

        Object (infos: infos);
    }

    protected override async void run_operation (OperationInfo info) throws Error {
        var source = File.new_for_uri (info.source_uri);
        var source_info = yield source.query_info_async ("standard::*", NONE, Priority.DEFAULT, cancellable);

        var destination = File.new_for_uri (info.data).get_child (source.get_basename ());

        yield copy_recursive (source, source_info, destination);
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
