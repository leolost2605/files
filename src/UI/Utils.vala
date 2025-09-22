/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

namespace Files.Utils {
    public static string enum_to_nick (Type enum_type, int value) {
        var enum_class = (EnumClass) enum_type.class_ref ();
        return enum_class.get_value (value).value_nick;
    }

    public async FileBase? get_home_directory () {
        return yield FileBase.get_for_path (Environment.get_home_dir ());
    }

    public async FileBase? get_trash_directory () {
        return yield FileBase.get_for_uri ("trash:///");
    }

    public async FileBase? get_special_directory (UserDirectory dir) {
        return yield FileBase.get_for_path (Environment.get_user_special_dir (dir));
    }
}
