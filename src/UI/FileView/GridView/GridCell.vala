/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.GridCell : Granite.Bin {
    private Binding? binding;

    private Gtk.Label label;

    construct {
        label = new Gtk.Label (null);
        child = label;
    }

    public void bind (FileBase file) {
        binding = file.bind_property ("basename", label, "label", SYNC_CREATE);
    }

    public void unbind () {
        binding.unbind ();
    }
}
