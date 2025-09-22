/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.OperationManager : Object {
    private static OperationManager? instance;

    public static unowned OperationManager get_instance () {
        if (instance == null) {
            instance = new OperationManager ();
        }

        return instance;
    }

    public signal void error_occurred (ErrorInfo info);

    public ListStore current_operations { get; construct; }
    public int n_pending { get { return pending_operations.size; } }

    private Gee.Queue<Operation> pending_operations;

    private Gee.Deque<Operation> undo_stack;

    construct {
        current_operations = new ListStore (typeof (Operation));
        pending_operations = new Gee.LinkedList<Operation> ();
        undo_stack = new Gee.LinkedList<Operation> ();
    }

    // Utility that checks whether to move or copy files and queues the according operation
    public async void paste_files (owned string[] sources, string destination) {
        string[] to_move = {};
        string[] to_copy = {};

        foreach (var source in sources) {
            var base_file = yield FileBase.get_for_uri (source);

            if (base_file.move_queued) {
                to_move += base_file.uri;
            } else {
                to_copy += base_file.uri;
            }
        }

        if (to_move.length > 0) {
            push_operation (new MoveOperation (to_move, destination));
        }

        if (to_copy.length > 0) {
            push_operation (new CopyOperation (to_copy, destination));
        }
    }

    public void rename_files (string[] uris, string[] new_names) {
        if (uris.length != new_names.length) {
            warning ("Source URIs and new names must have the same length.");
            return;
        }

        push_operation (new RenameOperation (uris, new_names));
    }

    public void push_operation (Operation operation) {
        if (current_operations.n_items >= 5) {
            pending_operations.offer (operation);
            notify_property ("n-pending");
        } else {
            start_operation (operation);
        }
    }

    private void start_operation (Operation operation) {
        current_operations.append (operation);
        operation.done.connect (on_operation_done);
        operation.error_occurred.connect ((info) => error_occurred (info));
        operation.start ();
    }

    private void on_operation_done (Operation operation) {
        uint pos;
        current_operations.find (operation, out pos);
        current_operations.remove (pos);

        if (pending_operations.size > 0) {
            start_operation (pending_operations.poll ());
            notify_property ("n-pending");
        }

        undo_stack.offer_head (operation);
    }

    public void undo_last () {
        undo_stack.poll_head ().undo ();
    }
}
