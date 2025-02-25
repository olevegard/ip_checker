const std = @import("std");
const nfc = @import("num_from_char.zig");
const ht = @import("hex_tools.zig");

pub fn do_ip_6_thing_handle_weirdness(cidr: []const u8) u128 {
    var ip_as_num: u128 = 0;
    const previous_part_mask: u128 = 0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000_00000000;
    const lowest_2_bytes_mask: u128 = ~previous_part_mask;
    var sep_count: u8 = 0;
    var double_sep_count_pos: u8 = 0;

    std.debug.print("Input {s}\n", .{cidr});

    for (0..cidr.len, cidr) |i, digit| {
        if (digit == '/') {
            break;
        }

        // This is stupid
        // It avoids a branch by multiplying with zero if digit is not ':'
        // Needs to be u7 because otherwise zig would think it's a u1 in some cases
        const is_sep: u7 = @intFromBool(digit == ':');
        sep_count += is_sep;
        const is_not_sep: u7 = 1 - is_sep;

        // Also stupid :
        // Add 1 to i if this value is a sep and use that as an index
        // Note : Will crash if last value is :
        // Also note : Will fail if there are more than one instance of "::"
        const next_val: u8 = cidr[i + is_sep];

        // Check if that value is ':'
        const is_next_val_sep: u8 = @intFromBool(next_val == ':');

        // is_sep is 0 if this digit is not ':'
        // is_next_val_sep is 0 if the next digit is not ':'
        // Only one instance of "::" is allowed
        // Note : we need to multiply with is_sep, since otherwise it would
        // always increment double_sep_count_pos if ther next value was ':'
        double_sep_count_pos += sep_count * is_sep * is_next_val_sep;

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

    std.debug.print(":: pos : {d} : count : {d}\n", .{ double_sep_count_pos, sep_count });
    print_ip_6(ip_as_num);
    std.debug.print("{d}\n", .{ip_as_num});

    return ip_as_num;
}

pub fn do_ip_6_thing(cidr: []const u8) u128 {
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
    std.debug.print("{d}\n", .{ip_as_num});

    return ip_as_num;
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

test do_ip_6_thing {
    const expected: u128 = 46881332410603363781561182369067770805;
    try std.testing.expect(do_ip_6_thing("2345:0425:2CA1:0000:0000:0567:5673:23b5") == expected);
}
