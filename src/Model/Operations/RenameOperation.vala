/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.RenameOperation : Operation {
    public RenameOperation (string[] source_uris, string[] new_names) {
        var infos = new Gee.ArrayList<OperationInfo> ();

        if (source_uris.length == new_names.length) {
            for (int i = 0; i < source_uris.length; i++) {
                infos.add (new OperationInfo (source_uris[i], new_names[i]));
            }
        } else {
            critical ("Source URIs and new names must have the same length. This is a programmer error and should be reported.");
        }

        Object (infos: infos);
    }

    protected override async void run_operation (OperationInfo info) throws Error {
        var source = File.new_for_uri (info.source_uri);
        var new_name = info.data;

        yield source.set_display_name_async (new_name, Priority.DEFAULT, cancellable);
    }
}
