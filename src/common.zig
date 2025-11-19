const C = @cImport({
    @cInclude("SDL3/SDL.h");
});

pub const FONT_SIZE: u32 = 8;
const font = @import("font.zig").font;
pub const SCREEN_SIZE: u32 = 160;

pub const BUTTON_1: u8 = 1 << 0;
pub const BUTTON_2: u8 = 1 << 1;
pub const BUTTON_LEFT: u8 = 1 << 4;
pub const BUTTON_RIGHT: u8 = 1 << 5;
pub const BUTTON_UP: u8 = 1 << 6;
pub const BUTTON_DOWN: u8 = 1 << 7;

pub const DrawColors = packed struct(u16) { color1: u4, color2: u4, color3: u4, color4: u4 };
pub var _draw_colors: DrawColors = .{ .color1 = 2, .color2 = 0, .color3 = 0, .color4 = 0 };
pub const DRAW_COLORS: *u16 = @ptrCast(&_draw_colors);

pub var _gamepad1: u8 = 0;
pub var GAMEPAD1 = &_gamepad1;

pub var _fb: *[SCREEN_SIZE * SCREEN_SIZE]u2 = undefined;

pub var _palette: [4]u32 = @splat(0xffffffff);
pub const PALETTE: *[4]u32 = &_palette;

const BPP = enum(u1) {
    @"1bb" = 0,
    @"2bb" = 1,
};

pub const BLIT_1BPP: u32 = @intFromEnum(BPP.@"1bb");
pub const BLIT_2BPP: u32 = @intFromEnum(BPP.@"2bb");

pub fn blit(data: [*]const u8, x: i32, y: i32, width: u32, height: u32, flags: u32) void {
    //convert data to [*]const u2
    const bpp: BPP = @enumFromInt(flags & 1);
    switch (bpp) {
        .@"1bb" => {
            // const pixels: [*]const u1 = @ptrCast(data);
            var px: u32 = 0;
            var py: u32 = 0;
            for (0..width * height) |pi| {
                px = pi % width;
                py = pi / width;
                // const std = @import("std");
                // _ = std.c.printf("px: %u py: %u  pi: %zu\n", px, py, pi);
                // const b = pixels[pi];
                const b: u1 = @truncate(data[pi / 8] >> @intCast(7 - (pi % 8)));
                // const pi = i*2;
                const screen_px = @as(i32, @intCast(px)) + x;
                const screen_py = @as(i32, @intCast(py)) + y;
                if (screen_px >= 0 and screen_py >= 0 and screen_px < SCREEN_SIZE and screen_py < SCREEN_SIZE) {
                    const uscreen_x: u32 = @intCast(screen_px);
                    const uscreen_y: u32 = @intCast(screen_py);
                    const index = uscreen_x + (uscreen_y * SCREEN_SIZE);
                    switch (b) {
                        0 => {
                            if (_draw_colors.color1 != 0) {
                                _fb[index] = @truncate(_draw_colors.color1 -| 1);
                            }
                        },
                        1 => {
                            if (_draw_colors.color2 != 0) {
                                _fb[index] = @truncate(_draw_colors.color2 -| 1);
                            }
                        },
                    }
                }
                // px += 1;
                // if (px == width) {
                //     px = 0;
                //     py += 1;
                // }
            }
        },
        .@"2bb" => {
            const pixels: [*]const u2 = @ptrCast(data);
            var px: u32 = 0;
            var py: u32 = 0;
            for (0..width * height) |pi| {
                const b = pixels[pi];
                const screen_px = @as(i32, @intCast(px)) + x;
                const screen_py = @as(i32, @intCast(py)) + y;
                if (screen_px > 0 and screen_py > 0 and screen_px < SCREEN_SIZE and screen_py < SCREEN_SIZE) {
                    const uscreen_x = @as(u32, @intCast(screen_px));
                    const uscreen_y = @as(u32, @intCast(screen_py));
                    const index = uscreen_x + (uscreen_y * SCREEN_SIZE);
                    switch (b) {
                        0 => {
                            if (_draw_colors.color1 != 0) {
                                _fb[index] = @truncate(_draw_colors.color1 -| 1);
                            }
                        },
                        1 => {
                            if (_draw_colors.color2 != 0) {
                                _fb[index] = @truncate(_draw_colors.color2 -| 1);
                            }
                        },
                        2 => {
                            if (_draw_colors.color3 != 0) {
                                _fb[index] = @truncate(_draw_colors.color3 -| 1);
                            }
                        },
                        3 => {
                            if (_draw_colors.color4 != 0) {
                                _fb[index] = @truncate(_draw_colors.color4 -| 1);
                            }
                        },
                    }
                }
                px += 1;
                if (px == width) {
                    px = 0;
                    py += 1;
                }
            }
        },
    }
}

pub fn text(str: []const u8, x: i32, y: i32) void {
    var px: i32 = x;
    var py: i32 = y;
    for (str) |b| {
        if (b == '\n') {
            py += 8;
            px = x;
        } else if (b >= 32 and b < font.len) {
            blit(&font[b - 32], px, py, 8, 8, 0);
            px += 8;
        } else {
            px += 8;
        }
    }
}

pub fn rect(x: i32, y: i32, width: u32, height: u32) void {
    var px = x;
    var py = y;
    while (py < height) : ({
        px = x;
        py += 1;
    }) {
        if (py < 0 or py > SCREEN_SIZE) continue;
        while (px < width) : (px += 1) {
            if (px < 0 or px > SCREEN_SIZE) continue;
            const index: usize = @intCast(px + (py * SCREEN_SIZE));
            if (_draw_colors.color2 != 0 and (px == 0 or py == 0 or px == width or py == width)) {
                _fb[index] = @truncate(_draw_colors.color2 - 1);
            } else if (_draw_colors.color1 != 0) {
                _fb[index] = @truncate(_draw_colors.color1 - 1);
            }
        }
    }
}
