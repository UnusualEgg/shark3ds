const w4 = @import("common.zig");
const std = @import("std");
const sdl = @import("sdl.zig");
//TODO use sdl and the texture atlas from main.zig

pub const surfer_width = 26;
pub const surfer_height = 26;
pub const water_width = 160;
pub const water_height = 12;

pub const shark_width = 49;
pub const shark_height = 36;

//everything is moved by surfer_speed
var surfer_speed: f32 = 0;
const max_speed: f32 = 5;
const surfer_x: i32 = 160 / 2;
const speed_change: f32 = 0.225;

var shark_x: i32 = 160;

const shark_speed: i32 = @as(i32, @intFromFloat(max_speed)) / 2;

var beam: i32 = 0;
const beam_width: i32 = 50;

var shark_alive: bool = true;

var prev_button2_state: bool = false;
var moved: bool = false;
pub fn update(ren: *sdl.Renderer, atlas: *sdl.Texture, title: *sdl.Texture, water: *sdl.Texture) !void {
    //update
    const gamepad = w4.GAMEPAD1.*;

    const curr_button2_state = gamepad & w4.BUTTON_2 != 0;
    if (curr_button2_state and !prev_button2_state and beam == 0) {
        shark_alive = true;
        surfer_speed = 0;
        shark_x = 160;
    }
    prev_button2_state = gamepad & w4.BUTTON_2 != 0;
    if (gamepad & (w4.BUTTON_LEFT | w4.BUTTON_RIGHT | w4.BUTTON_1) != 0) moved = true;

    if (gamepad & w4.BUTTON_1 != 0 and beam == 0 and shark_alive) {
        beam = beam_width;
        const shark_half = shark_width / 2;
        const shark_right = shark_x + shark_half;
        const shark_left = shark_x - shark_half;
        const screen_middle = 160 / 2;
        const beam_half = (beam_width / 2);
        const beam_left = screen_middle - beam_half;
        const beam_right = screen_middle + beam_half;
        if (shark_right >= beam_left and shark_left <= beam_right) {
            shark_alive = false;
        }
    }

    if (shark_alive) {
        if (gamepad & w4.BUTTON_RIGHT != 0) {
            surfer_speed += speed_change;
        }
        if (gamepad & w4.BUTTON_LEFT != 0) {
            surfer_speed -= speed_change;
        }
        if (surfer_speed < 0) {
            surfer_speed = 0;
        }
        if (surfer_speed > max_speed) {
            surfer_speed = max_speed;
        }
    }

    if (shark_alive) {
        shark_x += shark_speed;
        shark_x -= @intFromFloat(surfer_speed);
        //stop the shark at 4 screens ahead
        if (shark_x > 160 * 4) {
            shark_x = 160 * 4;
        }
    }

    //3 equally spaced states of rotation
    const surfer_index: usize =
        if (!shark_alive) 0 else if (surfer_speed >= (max_speed * (2.0 / 3.0))) 2 else if (surfer_speed > (max_speed / 3.0)) 1 else 0;
    //draw
    if (!moved) {
        // const title: []const u8 = "My dream game :3";
        //16 len
        try ren.renderTexture(title, null, &sdl.FRect{ .w = 8 * 16, .h = 16, .x = (160 / 2) - ((16 / 2) * 8), .y = 10 });
    }

    try draw_water(ren, water, @intFromFloat(surfer_speed));

    //surfer
    //blit uses top left corner for the position of sprites
    //so move surfer half over
    const surfer = [3]sdl.FRect{
        sdl.FRect{ .w = surfer_width, .h = surfer_height, .x = water_height + (surfer_width * 0), .y = shark_height + (surfer_height * 1) },
        sdl.FRect{ .w = surfer_width, .h = surfer_height, .x = water_height + (surfer_width * 1), .y = shark_height + (surfer_height * 0) },
        sdl.FRect{ .w = surfer_width, .h = surfer_height, .x = water_height + (surfer_width * 0), .y = shark_height + (surfer_height * 0) },
    };
    try ren.renderTexture(
        atlas,
        &surfer[surfer_index],
        &sdl.FRect{ .x = surfer_x - (surfer_width / 2), .y = 51, .w = surfer_width, .h = surfer_height },
    );

    //shark
    const shark = sdl.FRect{
        .x = water_height,
        .y = 0,
        .w = shark_width,
        .h = shark_height,
    };
    const shark_dest = sdl.FRect{
        .x = @floatFromInt(shark_x),
        .y = 92,
        .w = shark_width,
        .h = shark_height,
    };
    try ren.renderTexture(atlas, &shark, &shark_dest);

    if (beam > 0) {
        // w4.DRAW_COLORS.* = 0x0002;
        try ren.setDrawColor(255, 255, 255, 255);
        try ren.renderFillRect(&.{
            .x = @floatFromInt((surfer_x) - @divFloor(beam, 2)),
            .y = 0,
            .w = @floatFromInt(beam),
            .h = 160,
        });
    }
    //shrink beam over time
    beam -= 2;
    if (beam < 0) {
        beam = 0;
    }
}

var water_x: i32 = 0;
fn draw_water(ren: *sdl.Renderer, tex_water: *sdl.Texture, speed: i32) !void {
    //only the top of the water uses a sprite
    //water
    w4.DRAW_COLORS.* = 0x0030;
    const water_y: i32 = 60;
    //we use two to make it look endless
    const water = sdl.FRect{
        .x = 0,
        .y = 0,
        .w = water_width,
        .h = water_height,
    };
    const water_dest = sdl.FRect{
        .x = @floatFromInt(water_x),
        .y = @floatFromInt(water_y),
        .w = water_width,
        .h = water_height,
    };
    const water_dest2 = sdl.FRect{
        .x = @floatFromInt(water_x + 160),
        .y = @floatFromInt(water_y),
        .w = water_width,
        .h = water_height,
    };
    try ren.renderTexture(
        tex_water,
        &water,
        &water_dest,
    );
    try ren.renderTexture(
        tex_water,
        &water,
        &water_dest2,
    );

    if (shark_alive) {
        water_x -|= speed;
    }
    //them forward to keep looping so we never run out of water
    while (water_x <= -160) {
        water_x += 160;
    }

    //fill in bottom half of screen that isn't detailed and thus doesn't need a sprite
    try ren.setDrawColor(0x1d, 0x45, 0x6d, 255);
    try ren.renderFillRect(&.{ .x = 0, .y = water_y + water_height, .w = 160, .h = 160 - (water_y + water_height) });
}
