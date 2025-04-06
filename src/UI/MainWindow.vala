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
    public const string ACTION_GOTO = "goto";
    public const string ACTION_BACK = "back";
    public const string ACTION_FORWARD = "forward";
    public const string ACTION_NEW_TAB = "new-tab";
    public const string ACTION_VIEW_TYPE = "view-type";
    public const string ACTION_RENAME = "rename";

    private const ActionEntry[] ACTION_ENTRIES = {
        {ACTION_COPY, on_copy },
        {ACTION_CUT, on_cut },
        {ACTION_PASTE, on_paste },
        {ACTION_TRASH, on_trash },
        {ACTION_GOTO, on_goto, "s" },
        {ACTION_BACK, on_back, },
        {ACTION_FORWARD, on_forward, },
        {ACTION_NEW_TAB, on_new_tab, },
        {ACTION_VIEW_TYPE, null, "i" , "0", on_view_type_changed },
        {ACTION_RENAME, on_rename },
    };

    public Directory? directory {
        set {
            selected_view.directory = value;
            end_header.directory = value;
        }
    }

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

        var start_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Label ("")
        };
        start_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        start_header.pack_start (new Gtk.WindowControls (START));

        var start_box = new Gtk.Box (VERTICAL, 0);
        start_box.append (start_header);

        end_header = new HeaderBar ();

        tab_view = new Adw.TabView ();

        var tab_bar = new Adw.TabBar () {
            view = tab_view
        };

        var end_box = new Gtk.Box (VERTICAL, 0);
        end_box.add_css_class (Granite.STYLE_CLASS_VIEW);
        end_box.append (end_header);
        end_box.append (tab_bar);
        end_box.append (tab_view);

        var paned = new Gtk.Paned (HORIZONTAL) {
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

        on_new_tab ();
    }

    private void on_copy () {
        selected_view.copy (false);
    }

    private void on_cut () {
        selected_view.copy (true);
    }

    private void on_paste () {
        selected_view.paste.begin ();
    }

    private void on_trash () {
        selected_view.trash ();
    }

    private void on_goto (SimpleAction action, Variant? uri) {
        goto.begin ((string) uri);
    }

    private async void goto (string uri) {
        var file = yield FileBase.get_for_uri ((string) uri);

        if (file == null) {
            directory = null;
            return;
        }

        if (file is Directory) {
            directory = (Directory) file;
        } else {
            directory = yield file.get_parent ();
            //todo select file
        }
    }

    private void on_back () {
        selected_view.back ();
    }

    private void on_forward () {
        selected_view.forward ();
    }

    private void on_new_tab () {
        var file_view = new FileView ();
        var page = tab_view.append (file_view);

        file_view.bind_property ("directory", page, "title", SYNC_CREATE, (binding, from, ref to) => {
            var directory = (Directory) from.get_object ();
            if (directory != null) {
                to.set_string (directory.basename);
            } else {
                to.set_string ("n/a");
            }
            return true;
        });

        tab_view.selected_page = page;

        try {
            var home_uri = Filename.to_uri (Environment.get_home_dir (), null);
            activate_action_variant (MainWindow.ACTION_PREFIX + MainWindow.ACTION_GOTO, home_uri);
        } catch (Error e) {
            warning ("Error converting path to URI: %s", e.message);
        }
    }

    private void on_view_type_changed (SimpleAction action, Variant view_type) {
        selected_view.view_type = (ViewType) view_type.get_int32 ();
        action.set_state (view_type);
    }

    private void on_rename () {
        selected_view.rename ();
    }
}
