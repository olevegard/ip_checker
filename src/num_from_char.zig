const std = @import("std");

const A_to_digit = 'A' - 10;
const a_to_digit = 'a' - 10;

pub fn dec_to_char(char: u4) u8 {
    return switch (char) {
        0...9 => '0' + @as(u8, char),
        10...15 => ('a' + @as(u8, char)) - 10,
    };
}

pub fn num_from_char(char: u8) u8 {
    var digit: u8 = char;
    const is_digit: u8 = @intFromBool(char >= '0' and char <= '9');
    digit -= ('0' * is_digit);

    const is_uc_hex: u8 = @intFromBool(char >= 'A' and char <= 'F');
    digit -= A_to_digit * is_uc_hex;

    const is_lc_hex: u8 = @intFromBool(char >= 'a' and char <= 'f');
    digit -= a_to_digit * is_lc_hex;

    // If char was not a valid hex digit, set digit to 0
    digit *= @intFromBool(digit != char);

    return digit;
}

test num_from_char {
    for (0..255) |i| {
        const input: u8 = @intCast(i);
        const result = num_from_char(input);

        const expected: u8 = switch (i) {
            '0'...'9' => input - '0',
            'A'...'F' => input - A_to_digit,
            'a'...'f' => input - a_to_digit,
            else => 0,
        };

        std.testing.expect(result == expected) catch |err| {
            std.debug.print(
                "num_from_char for {d} ( {u} ) failed! Got {d}, expected {d}\n",
                .{ i, input, result, expected },
            );
            return err;
        };
    }
}
