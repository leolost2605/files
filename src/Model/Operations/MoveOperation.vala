/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.MoveOperation : ConflictableOperation {
    public string[] source_uris { get; construct; }
    public string destination_uri { get; construct; }

    public MoveOperation (string[] source_uris, string destination_uri) {
        Object (source_uris: source_uris, destination_uri: destination_uri);
    }

    public override void start () {
        move.begin ();
    }

    private async void move () {
        foreach (var uri in source_uris) {
            var source = File.new_for_uri (uri);
            var destination = File.new_build_filename (destination_uri, source.get_basename ());

            try {
                yield run_conflict_op (source, destination, MOVE);
            } catch (Error e) {
                report_error ("Failed to move file %s to %s: %s".printf (source.get_uri (), destination.get_uri (), e.message));
            }
        }

        done ();
    }
}
