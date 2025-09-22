/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.MoveOperation : ConflictableOperation {
    public MoveOperation (string[] source_uris, string destination_uri) {
        var infos = new Gee.ArrayList<OperationInfo> ();
        for (int i = 0; i < source_uris.length; i++) {
            infos.add (new OperationInfo (source_uris[i], destination_uri));
        }

        Object (infos: infos);
    }

    protected override async void run_operation (OperationInfo info) throws Error {
        var source = File.new_for_uri (info.source_uri);
        var destination = File.new_for_uri (info.data).get_child (source.get_basename ());
        yield run_conflict_op (source, destination, MOVE);
    }
}
