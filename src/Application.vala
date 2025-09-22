/*
* SPDX-License-Identifier: GPL-3.0-or-later
* SPDX-FileCopyrightText: {{YEAR}} {{DEVELOPER_NAME}} <{{DEVELOPER_EMAIL}}>
*/

private static Settings settings;

public class Files.Application : Gtk.Application {
    public const string ACTION_PREFIX = "app.";
    public const string ACTION_SHOW_HIDDEN_FILES = "show-hidden-files";
    public const string ACTION_SORT_FOLDERS_BEFORE_FILES = "sort-folders-before-files";

    static construct {
        settings = new Settings ("io.github.leolost2605.files");
    }

    public MainWindow main_window;

    public Application () {
        Object (
            application_id: "io.github.leolost2605.files",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void startup () {
        base.startup ();

        Granite.init ();
        FileBase.init ();

        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

        var quit_action = new SimpleAction ("quit", null);

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q"});

        quit_action.activate.connect (quit);

        add_action (settings.create_action (ACTION_SHOW_HIDDEN_FILES));
        add_action (settings.create_action (ACTION_SORT_FOLDERS_BEFORE_FILES));

        // Set default elementary thme
        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.gtk_icon_theme_name = "elementary";
        if (!(gtk_settings.gtk_theme_name.has_prefix ("io.elementary.stylesheet"))) {
            gtk_settings.gtk_theme_name = "io.elementary.stylesheet.blueberry";
        }

        unowned Gtk.IconTheme default_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
        default_theme.add_resource_path ("io/github/leolost2605/files/");

        OperationManager.get_instance ().error_occurred.connect (on_operation_error);
    }

    protected override void activate () {
        if (main_window != null) {
            main_window.present ();
            return;
        }

        var main_window = new MainWindow (this);

        /*
        * This is very finicky. Bind size after present else set_titlebar gives us bad sizes
        * Set maximize after height/width else window is min size on unmaximize
        * Bind maximize as SET else get get bad sizes
        */
        settings.bind ("window-height", main_window, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-width", main_window, "default-width", SettingsBindFlags.DEFAULT);

        if (settings.get_boolean ("window-maximized")) {
            main_window.maximize ();
        }

        settings.bind ("window-maximized", main_window, "maximized", SettingsBindFlags.SET);

        // Use Css
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/io/github/leolost2605/files/Application.css");

        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        main_window.present ();
    }

    private void on_operation_error (ErrorInfo info) {
        var dialog = new Granite.MessageDialog (
            "An error occurred",
            "An error occurred while performing a file operation",
            new ThemedIcon ("dialog-error")
        ) {
            transient_for = active_window,
        };
        dialog.show_error_details (info.message);
        dialog.present ();

        // TODO: Base on user input from dialog
        info.response (SKIP);
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}
