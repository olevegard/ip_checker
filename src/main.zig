const std = @import("std");
const nfc = @import("num_from_char.zig");
const ht = @import("hex_tools.zig");

pub fn main() !void {
    do_ip_thing("212.21.149.4/21");

    //                         1          2            3
    //             1234 5678 9012 3456 7890 1234 5678 9012
    const cidr: []const u8 = "2345:0425:2CA1:0000:0000:0567:5673:23b5";
    _ = cidr.len;
    do_ip_6_thing(cidr);
    std.debug.print("{s}\n", .{ht.dec_to_hex(15)});
}

const eight: u32 = 8;

pub fn do_ip_6_thing(cidr: []const u8) void {
    var ip_as_num: u128 = 0;
    const previous_part_mask: u128 = 0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000_00000000;
    const lowest_2_bytes_mask: u128 = ~previous_part_mask;

    std.debug.print("Input {s}\n", .{cidr});

    for (0..cidr.len, cidr) |_, digit| {
        if (digit == '/') {
            break;
        }

        // This is stupid
        // It avoids a branch by multiplying with zero if digit is not ':'
        // Needs to be u7 because otherwise zig would think it's a u1 in some cases
        const is_sep: u7 = @intFromBool(digit == ':');
        const is_not_sep: u7 = 1 - is_sep;

        // Shift the number 16 to the left if we're at a ':'
        // Note : If is_sep was a u1 here, 16 * is_sep would throw a compile error
        ip_as_num <<= 16 * is_sep;

        // Isolate the lowest 2 bytes
        var lowest_byte = ip_as_num & lowest_2_bytes_mask;

        // Multiply by 16 so we can add the next character
        // If this is the first character, lowest_byte will be 0
        lowest_byte *= 16 * is_not_sep;

        // Finally we add the digit itself
        // Note that adding it is always safe, since digit will be 0 if we're at a dot
        lowest_byte += nfc.num_from_char(digit);

        // Separate the left parts of the number ( xxx.xxx.xxx. )
        // so that we don't change it
        const original_num = ip_as_num & previous_part_mask;

        // Add the new lowest byte with the original left part
        ip_as_num = original_num + lowest_byte;
    }

    print_ip_6(ip_as_num);
}

pub fn hex_to_dec(cidr: [*:0]const u8) u32 {
    var num: u32 = 0;
    for (0..16) |i| {
        const digit = nfc.num_from_char(cidr[i]);

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

        digit = nfc.num_from_char(digit);

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
    const sz = 0b11111111_11111111;

    std.debug.print(
        "CIDR : {s}:{s}:{s}:{s}:{s}:{s}:{s}:{s}\n",
        .{
            ht.dec_to_hex(@intCast((ip >> 112) & sz)),
            ht.dec_to_hex(@intCast((ip >> 96) & sz)),
            ht.dec_to_hex(@intCast((ip >> 80) & sz)),
            ht.dec_to_hex(@intCast((ip >> 64) & sz)),
            ht.dec_to_hex(@intCast((ip >> 48) & sz)),
            ht.dec_to_hex(@intCast((ip >> 32) & sz)),
            ht.dec_to_hex(@intCast((ip >> 16) & sz)),
            ht.dec_to_hex(@intCast((ip >> 0) & sz)),
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

        digit = nfc.num_from_char(digit);

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
