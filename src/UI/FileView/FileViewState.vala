/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Files.FileViewState : Object {
    public const string ACTION_BACK = "back";
    public const string ACTION_FORWARD = "forward";
    public const string ACTION_LOCATION = "location";
    public const string ACTION_VIEW_TYPE = "view-type";
    public const string ACTION_SORT_KEY = "sort-key";
    public const string ACTION_SORT_DIRECTION = "sort-direction";

    private Directory? _directory;
    public Directory? directory {
        get { return _directory; }
        set {
            if (_directory == value) {
                return;
            }

            if (_directory != null) {
                _directory.queue_unload ();
            }

            _directory = value;

            if (history.size - 1 > current_index && history.get (current_index + 1) != value) {
                for (int i = current_index + 1; i < history.size; i++) {
                    history.remove_at (i);
                }
            }

            if (value != null) {
                value.load ();

                if (current_index > 0 && value == history.get (current_index - 1)) {
                    current_index--;
                } else if (history.size - 1 > current_index && value == history.get (current_index + 1)) {
                    current_index++;
                } else {
                    history.add (value);
                    current_index++;
                }
            }

            location_action.set_state (value?.uri);
            back_action.set_enabled (current_index > 0);
            forward_action.set_enabled (current_index < history.size - 1);
        }
    }

    public ViewType view_type { get; set; }
    public CellType sort_key { get; set; }
    public Gtk.SortType sort_direction { get; set; }

    public Gee.List<Action> actions { get; construct; }

    private Gee.ArrayList<Directory> history;
    private int current_index;

    private SimpleAction location_action;
    private SimpleAction back_action;
    private SimpleAction forward_action;

    construct {
        history = new Gee.ArrayList<Directory> ();
        current_index = -1;

        location_action = new SimpleAction.stateful (ACTION_LOCATION, new VariantType ("s"), new Variant.string (""));
        location_action.change_state.connect (on_location_action_change_state);
        location_action.activate.connect ((param) => location_action.change_state (param));

        back_action = new SimpleAction (ACTION_BACK, null);
        back_action.set_enabled (false);
        back_action.activate.connect (go_back);

        forward_action = new SimpleAction (ACTION_FORWARD, null);
        forward_action.set_enabled (false);
        forward_action.activate.connect (go_forward);

        actions = new Gee.ArrayList<Action> ();
        actions.add (location_action);
        actions.add (back_action);
        actions.add (forward_action);
        actions.add (new PropertyAction (ACTION_VIEW_TYPE, this, "view-type"));
        actions.add (new PropertyAction (ACTION_SORT_KEY, this, "sort-key"));
        actions.add (new PropertyAction (ACTION_SORT_DIRECTION, this, "sort-direction"));
    }

    private async void on_location_action_change_state (Variant? new_value) {
        if (new_value == null || new_value.get_type_string () != "s") {
            return;
        }

        var uri = new_value.get_string ();
        var file = yield FileBase.get_for_uri (uri);

        if (file is Directory) {
            directory = (Directory) file;
        }
    }

    private void go_back () {
        directory = history.get (current_index - 1);
    }

    private void go_forward () {
        directory = history.get (current_index + 1);
    }
}
