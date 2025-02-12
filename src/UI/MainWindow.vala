/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.MainWindow : Gtk.ApplicationWindow {
    public const string ACTION_GROUP_PREFIX = "win";
    public const string ACTION_PREFIX = ACTION_GROUP_PREFIX + ".";
    public const string ACTION_COPY = "copy";
    public const string ACTION_CUT = "cut";
    public const string ACTION_PASTE = "paste";
    public const string ACTION_TRASH = "trash";

    private const ActionEntry[] ACTION_ENTRIES = {
        {ACTION_COPY, on_copy },
        {ACTION_CUT, on_cut },
        {ACTION_PASTE, on_paste },
        {ACTION_TRASH, on_trash },
    };

    private MainView main_view;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            default_height: 300,
            default_width: 300,
            icon_name: "io.github.leolost2605.files",
            title: _("Files")
        );
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);

        var application = (Gtk.Application) GLib.Application.get_default ();
        application.set_accels_for_action (ACTION_PREFIX + ACTION_COPY, {"<Ctrl>c"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_CUT, {"<Ctrl>x"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_PASTE, {"<Ctrl>v"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_TRASH, {"Del"});

        var start_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Label ("")
        };
        start_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        start_header.pack_start (new Gtk.WindowControls (Gtk.PackType.START));

        var start_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        start_box.append (start_header);

        var end_header = new Gtk.HeaderBar () {
            show_title_buttons = false
        };
        end_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        end_header.pack_end (new Gtk.WindowControls (Gtk.PackType.END));

        main_view = new MainView ();

        var end_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        end_box.add_css_class (Granite.STYLE_CLASS_VIEW);
        end_box.append (end_header);
        end_box.append (main_view);

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            position = 275,
            start_child = start_box,
            end_child = end_box,
            resize_start_child = false,
            shrink_end_child = false,
            shrink_start_child = false
        };

        var null_title = new Gtk.Grid () {
            visible = false
        };

        titlebar = null_title;
        child = paned;
    }

    private void on_copy () {
        main_view.copy (false);
    }

    private void on_cut () {
        main_view.copy (true);
    }

    private void on_paste () {
        main_view.paste.begin ();
    }

    private void on_trash () {
        main_view.trash ();
    }
}
