/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.TrashOperation : Operation {
    public TrashOperation (string[] source_uris) {
        var infos = new Gee.ArrayList<OperationInfo> ();
        for (int i = 0; i < source_uris.length; i++) {
            infos.add (new OperationInfo (source_uris[i], null));
        }
        Object (infos: infos);
    }

    protected override async void run_operation (OperationInfo info) throws Error {
        var source = File.new_for_uri (info.source_uri);
        yield source.trash_async (Priority.DEFAULT, cancellable);
    }
}
