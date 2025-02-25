const std = @import("std");

pub fn main() !void {
    do_ip_thing("212.21.149.4/21");

    //                         1          2            3
    //             1234 5678 9012 3456 7890 1234 5678 9012
    do_ip_6_thing("2345:0425:2CA1:0000:0000:0567:5673:23b5");
    std.debug.print("{s}\n", .{dec_to_hex(15)});
}

const eight: u32 = 8;

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

const A_to_digit = 'A' - 10;
const a_to_digit = 'a' - 10;

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

pub fn do_ip_6_thing(cidr: [*:0]const u8) void {
    std.debug.print("Cidr {s}\n", .{cidr});

    var full: u128 = 0;
    const mask: u128 = 0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000_00000000;

    for (0..235) |i| {
        var digit: u8 = cidr[i];
        if (digit == 0 or digit == '/') {
            break;
        }
        // This is stupid
        // It avoids a branch by multiplying with zero if digit is not "."
        // Needs to be u7 because instead zig will think it's a u1 in some cases
        const is_dot: u7 = @intFromBool(digit == ':');
        const is_not_dot: u7 = 1 - is_dot;

        digit = num_from_char(digit);

        // Shift the number 16 to the left if we're at a dot
        full <<= 16 * is_dot;

        // Separate the left parts of the number ( xxx.xxx.xxx. )
        // so that we don't change it
        const original_num = (full & mask);

        // Isolate the lowest byte
        var lowest_byte = full & 0b11111111_11111111;

        // Multiply by ten so we can add the next character
        // If this is the first character, lowest_byte will be 0
        // So multiplying by 10 only does anything starting at the 2nd char
        lowest_byte *= 16 * is_not_dot;

        // Finally we add the digit itself
        // Note that adding it is always safe, since digit will be 0 if we're at a dot
        lowest_byte += digit;
        std.debug.print("Lowest byte {d} digit {d} noot doot {d}\n", .{ lowest_byte, digit, is_not_dot });
        //
        //

        // Add the new lowest byte with the original left part
        full = original_num + lowest_byte;
    }

    var prev_lowest_byte = full & 0b11111111_1111111_00000000_0000000;
    prev_lowest_byte >>= 16;
    std.debug.print("Lowest byte {d}\n", .{prev_lowest_byte});
    print_ip_6(full);
}

pub fn dec_to_hex(cidr: u16) [4:0]u8 {
    //aasd
    const c1: u8 = @intCast((cidr & 0b1111_0000_0000_0000) >> 12);
    const c2: u8 = @intCast((cidr & 0b0000_1111_0000_0000) >> 8);
    const c3: u8 = @intCast((cidr & 0b0000_0000_1111_0000) >> 4);
    const c4: u8 = @intCast((cidr & 0b0000_0000_0000_1111) >> 0);
    return [4:0]u8{
        dec_to_char(@intCast(c1 & 0b1111)),
        dec_to_char(@intCast(c2 & 0b1111)),
        dec_to_char(@intCast(c3 & 0b1111)),
        dec_to_char(@intCast(c4 & 0b1111)),
    };

    // const first = cidr & 0b1111_0000_0000_0000;
}

pub fn dec_to_char(char: u4) u8 {
    return switch (char) {
        0...9 => '0' + @as(u8, char),
        10...15 => ('a' + @as(u8, char)) - 10,
    };
}
pub fn hex_to_dec(cidr: [*:0]const u8) u32 {
    var num: u32 = 0;
    for (0..16) |i| {
        const digit = num_from_char(cidr[i]);

        if (digit == 0 or digit == '/') {
            break;
        }

        num *= 16;
        num += digit;
    }

    return num;
}
pub fn do_ip_thing(cidr: [*:0]const u8) void {
    std.debug.print("Cidr {s}\n", .{cidr});

    var full: u32 = 0;
    const mask: u32 = 0b11111111_11111111_11111111_00000000;

    for (0..16) |i| {
        var digit: u8 = cidr[i];
        if (digit == 0 or digit == '/') {
            break;
        }
        // This is stupid
        // It avoids a branch by multiplying with zero if digit is not "."
        const is_dot: u4 = @intFromBool(digit == '.');
        const is_not_dot: u4 = 1 - is_dot;

        digit = num_from_char(digit);

        // Shift the number 8 to the left if we're at a dot
        full <<= 8 * is_dot;

        // Separate the left parts of the number ( xxx.xxx.xxx. )
        // so that we don't change it
        const original_num = (full & mask);

        // Isolate the lowest byte
        var lowest_byte = full & 255;

        // Multiply by ten so we can add the next character
        // If this is the first character, lowest_byte will be 0
        // So multiplying by 10 only does anything starting at the 2nd char
        lowest_byte *= 10 * is_not_dot;

        // Finally we add the digit itself
        // Note that adding it is always safe, since digit will be 0 if we're at a dot
        lowest_byte += digit;

        // Add the new lowest byte with the original left part
        full = original_num + lowest_byte;
    }

    print_ip(full);
}

pub fn print_ip(ip: u32) void {
    std.debug.print(
        "CIDR : {b:_>32} split {d}.{d}.{d}.{d}\n",
        .{
            ip,
            (ip >> 24) & 255,
            (ip >> 16) & 255,
            (ip >> 8) & 255,
            (ip >> 0) & 255,
        },
    );
}

pub fn print_ip_6(ip: u128) void {
    //           12345678_12345678
    const sz = 0b11111111_11111111;
    std.debug.print(
        "CIDR : {b:_>32} split {d}:{d}:{d}:{d}:{d}:{d}:{d}:{d}\n",
        .{
            ip,
            (ip >> 112) & sz,
            (ip >> 96) & sz,
            (ip >> 80) & sz,
            (ip >> 64) & sz,
            (ip >> 48) & sz,
            (ip >> 32) & sz,
            (ip >> 16) & sz,
            (ip >> 0) & sz,
        },
    );
    std.debug.print(
        "CIDR : {s}:{s}:{s}:{s}:{s}:{s}:{s}:{s}\n",
        .{
            dec_to_hex(@intCast((ip >> 112) & sz)),
            dec_to_hex(@intCast((ip >> 96) & sz)),
            dec_to_hex(@intCast((ip >> 80) & sz)),
            dec_to_hex(@intCast((ip >> 64) & sz)),
            dec_to_hex(@intCast((ip >> 48) & sz)),
            dec_to_hex(@intCast((ip >> 32) & sz)),
            dec_to_hex(@intCast((ip >> 16) & sz)),
            dec_to_hex(@intCast((ip >> 0) & sz)),
        },
    );
}

pub fn do_ip_thin(cidr: [*:0]const u8) void {
    std.debug.print("Cidr {s}\n", .{cidr});

    var part: u8 = 0;
    var full: u32 = 0;
    for (0..16) |i| {
        var digit: u8 = cidr[i];
        if (digit == 0) {
            break;
        }

        if (digit == '/') {
            break;
        }

        // This is stupid
        // It avoids a branch by multiplying with zero if digit is not "."
        const is_dot: u8 = @intFromBool(digit == '.');
        const is_not_dot: u8 = 1 - is_dot;

        // If current char is a dot, at the current part to full
        full += (part * is_dot);
        // .. Then shift it by eight
        full <<= @intCast(is_dot * 8);
        // .. Then set part to 0
        part *= is_not_dot;

        digit = num_from_char(digit);

        // If digit is a number, multiply the previous part by 10
        part *= (10 * is_not_dot); // + digit;

        // Then add the current digit to it
        // Digit is zero if it's not a valid hex char
        part += digit;
    }

    full += part;

    std.debug.print(
        "Full : {b:_>32} split {d}.{d}.{d}.{d}\n",
        .{
            full,
            (full >> 24) & 255,
            (full >> 16) & 255,
            (full >> 8) & 255,
            (full >> 0) & 255,
        },
    );
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
