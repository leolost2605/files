/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public abstract class Files.Operation : Object {
    public signal void done ();
    public signal void report_error (string message) {
        warning (message);
    }

    public double progress { get; private set; }
    public Cancellable cancellable { protected get; construct; }

    construct {
        cancellable = new Cancellable ();
    }

    public virtual void start () { }
    public virtual void undo () { }

    public void cancel () {
        cancellable.cancel ();
        done ();
    }
}
