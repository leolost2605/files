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
    public const string ACTION_NEW_TAB = "new-tab";
    public const string ACTION_RENAME = "rename";
    public const string ACTION_OPEN = "open";
    public const string ACTION_NEW_FOLDER = "new-folder";

    private const ActionEntry[] ACTION_ENTRIES = {
        {ACTION_COPY, on_copy },
        {ACTION_CUT, on_cut },
        {ACTION_PASTE, on_paste },
        {ACTION_TRASH, on_trash },
        {ACTION_NEW_TAB, on_new_tab, },
        {ACTION_RENAME, on_rename },
        {ACTION_OPEN, on_open, "i" },
        {ACTION_NEW_FOLDER, on_new_folder },
    };

    public signal void location_changed (string new_location);

    public FileView selected_view {
        get { return (FileView) tab_view.selected_page.child; }
    }

    private HeaderBar end_header;
    private Adw.TabView tab_view;

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
        application.set_accels_for_action (ACTION_PREFIX + ACTION_NEW_TAB, {"<Ctrl>t"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_RENAME, {"F2"});

        end_header = new HeaderBar ();

        tab_view = new Adw.TabView ();
        tab_view.notify["selected-page"].connect (on_selected_tab_changed);

        var tab_bar = new Adw.TabBar () {
            view = tab_view
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = tab_view
        };
        toolbar_view.add_top_bar (end_header);
        toolbar_view.add_top_bar (tab_bar);

        var split_view = new Adw.NavigationSplitView () {
            sidebar = new Adw.NavigationPage (new Sidebar (), _("Sidebar")),
            content = new Adw.NavigationPage (toolbar_view, _("Files"))
        };

        var null_title = new Gtk.Grid () {
            visible = false
        };

        titlebar = null_title;
        child = split_view;

        action_added.connect (on_action_added);
        action_state_changed.connect (on_action_state_changed);

        on_new_tab ();
    }

    private void on_selected_tab_changed () {
        var file_view = (FileView) tab_view.selected_page.child;

        foreach (var action in file_view.state.actions) {
            add_action (action);
        }
    }

    private void on_copy () {
        selected_view.copy (false);
    }

    private void on_cut () {
        selected_view.copy (true);
    }

    private void on_paste () {
        selected_view.paste ();
    }

    private void on_trash () {
        selected_view.trash ();
    }

    private void on_new_tab () {
        var state = new FileViewState ();
        var file_view = new FileView (state);
        var page = tab_view.append (file_view);

        state.bind_property ("directory", page, "title", SYNC_CREATE, (binding, from, ref to) => {
            var directory = (Directory) from.get_object ();
            if (directory != null) {
                to.set_string (directory.display_name);
            } else {
                to.set_string ("n/a");
            }
            return true;
        });

        tab_view.selected_page = page;

        try {
            var home_uri = Filename.to_uri (Environment.get_home_dir (), null);
            activate_action_variant (MainWindow.ACTION_PREFIX + FileViewState.ACTION_LOCATION, home_uri);
        } catch (Error e) {
            warning ("Error converting path to URI: %s", e.message);
        }
    }

    private void on_rename () {
        selected_view.rename ();
    }

    private void on_open (SimpleAction action, Variant? param) {
        selected_view.open ((OpenHint) param.get_int32 ());
    }

    private void on_new_folder (SimpleAction action, Variant? param) {
        selected_view.create_new_folder ();
    }

    private void on_action_added (string action_name) {
        if (action_name == FileViewState.ACTION_LOCATION) {
            on_action_state_changed (action_name, get_action_state (action_name));
        }
    }

    private void on_action_state_changed (string action, Variant new_state) {
        if (action == FileViewState.ACTION_LOCATION) {
            location_changed (new_state.get_string ());
        }
    }
}
