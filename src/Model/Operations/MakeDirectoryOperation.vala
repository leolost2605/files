/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.MakeDirectoryOperation : Operation {
    public MakeDirectoryOperation (string[] uris) {
        var infos = new Gee.ArrayList<OperationInfo> ();
        for (int i = 0; i < uris.length; i++) {
            infos.add (new OperationInfo (uris[i], null));
        }
        Object (infos: infos);
    }

    public override string? calculate_resulting_uri (OperationInfo info) {
        return info.source_uri;
    }

    protected override async void run_operation (OperationInfo info) throws Error {
        var source = File.new_for_uri (info.source_uri);
        yield source.make_directory_async (Priority.DEFAULT, cancellable);
    }
}
