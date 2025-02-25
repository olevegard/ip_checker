const nfc = @import("num_from_char.zig");

pub fn dec_to_hex(cidr: u16) [4:0]u8 {
    const c1: u8 = @intCast((cidr & 0b1111_0000_0000_0000) >> 12);
    const c2: u8 = @intCast((cidr & 0b0000_1111_0000_0000) >> 8);
    const c3: u8 = @intCast((cidr & 0b0000_0000_1111_0000) >> 4);
    const c4: u8 = @intCast((cidr & 0b0000_0000_0000_1111) >> 0);

    return [4:0]u8{
        nfc.dec_to_char(@intCast(c1 & 0b1111)),
        nfc.dec_to_char(@intCast(c2 & 0b1111)),
        nfc.dec_to_char(@intCast(c3 & 0b1111)),
        nfc.dec_to_char(@intCast(c4 & 0b1111)),
    };
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
