/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public enum Files.ErrorResponse {
    SKIP,
    SKIP_REMAINING
}

public class Files.ErrorInfo : Object {
    internal signal void response (ErrorResponse response);

    public string message { get; construct; }
    public int n_remaining { get; construct; }

    public ErrorInfo (string message, int n_remaining) {
        Object (message: message, n_remaining: n_remaining);
    }
}

public class Files.OperationInfo : Object {
    public string source_uri { get; construct; }
    public string? data { get; construct; }

    public OperationInfo (string source_uri, string? data) {
        Object (source_uri: source_uri, data: data);
    }
}

public abstract class Files.Operation : Object {
    public signal void done ();
    public signal void error_occurred (ErrorInfo info) {
        warning (info.message);
    }

    public Gee.List<OperationInfo> infos { get; construct; }

    public double progress { get; private set; }
    public Cancellable cancellable { protected get; construct; }

    construct {
        cancellable = new Cancellable ();
    }

    public void start () {
        run.begin ();
    }

    private async void run () {
        int operations_done = 0;
        foreach (var info in infos) {
            if (cancellable.is_cancelled ()) {
                break;
            }

            try {
                yield run_operation (info);
            } catch (Error e) {
                var response = yield report_error (e.message, infos.size - operations_done);

                switch (response) {
                    case SKIP:
                        continue;
                    case SKIP_REMAINING:
                        break;
                }
            } finally {
                operations_done++;
                progress = (double) operations_done / (double) infos.size;
            }
        }

        done ();
    }

    private async ErrorResponse report_error (string message, int n_remaining) {
        var info = new ErrorInfo (message, n_remaining);

        ErrorResponse response = SKIP;
        info.response.connect ((resp) => {
            response = resp;
            Idle.add_once (() => report_error.callback ());
        });

        error_occurred (info);

        yield;

        return response;
    }

    protected abstract async void run_operation (OperationInfo info) throws Error;

    public void undo () {
        // TODO
    }

    public void cancel () {
        cancellable.cancel ();
        done ();
    }
}
