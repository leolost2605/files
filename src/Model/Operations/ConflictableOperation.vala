/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public enum Files.Resolution {
    NONE,
    SKIP,
    OVERWRITE,
    RENAME,
    CANCEL
}

public class Files.ConflictInfo : Object {
    public Resolution resolution { get; private set; default = NONE; }
    public bool apply_to_all { get; private set; default = false; }
    public string? new_basename { get; private set; default = null; }

    public void resolve (Resolution resolution, bool apply_to_all, string? new_basename = null) requires (resolution != RENAME || !apply_to_all && new_basename != null) {
        this.resolution = resolution;
        this.apply_to_all = apply_to_all;
        this.new_basename = new_basename;
    }

    public File calculate_destination (File destination) {
        if (new_basename == null) {
            return destination;
        }

        var new_destination = destination.get_parent ().get_child (new_basename);

        if (!apply_to_all) {
            new_basename = null;
        }

        return new_destination;
    }

    public FileCopyFlags calculate_flags () {
        return resolution == OVERWRITE ? FileCopyFlags.OVERWRITE : FileCopyFlags.NONE;
    }
}

public abstract class Files.ConflictableOperation : Operation {
    public enum ActionType {
        COPY,
        MOVE
    }

    public delegate void ResolveFunc (Resolution resolution, bool apply_to_all, string? new_basename = null);

    public signal void ask_user (File source, File destination, owned ResolveFunc callback) {
        warning ("Asking resolve, choosing skip");
        callback (SKIP, false);
    }

    private ConflictInfo conflict_info;

    construct {
        conflict_info = new ConflictInfo ();
    }

    protected async void run_conflict_op (File source, File destination, ActionType action_type) throws Error {
        try {
            yield action (source, destination, action_type);
        } catch (IOError.EXISTS e) {
            yield ask (source, destination);

            switch (conflict_info.resolution) {
                case SKIP:
                    return;

                case CANCEL:
                    cancel ();
                    return;

                case OVERWRITE:
                case RENAME:
                    yield run_conflict_op (source, destination, action_type); // Flags/new destination will be set automatically
                    return;

                default:
                    assert_not_reached ();
            }
        }
    }

    private async void action (File source, File original_destination, ActionType action_type) throws Error {
        var destination = conflict_info.calculate_destination (original_destination);
        var flags = conflict_info.calculate_flags ();

        switch (action_type) {
            case COPY:
                yield source.copy_async (destination, flags, Priority.DEFAULT, cancellable, null);
                break;

            case MOVE:
                yield source.move_async (destination, flags, Priority.DEFAULT, cancellable, null);
                break;
        }
    }

    private async void ask (File source, File destination) {
        if (conflict_info.apply_to_all) {
            return;
        }

        ask_user (source, destination, (resolution, apply_to_all, new_basename) => {
            conflict_info.resolve (resolution, apply_to_all, new_basename);
            Idle.add_once (() => ask.callback ());
        });

        yield;
    }
}
