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
