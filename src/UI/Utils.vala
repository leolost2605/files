/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

namespace Utils {
    public static string enum_to_nick (Type enum_type, int value) {
        var enum_class = (EnumClass) enum_type.class_ref ();
        return enum_class.get_value (value).value_nick;
    }
}
