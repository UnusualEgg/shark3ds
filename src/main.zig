const std = @import("std");
// const sdlzig = @import("sdlzig");
const C = @cImport({
    @cInclude("SDL3/SDL.h");
});
const DS = @cImport({
    @cInclude("3ds.h");
});
const sdl = @import("sdl.zig");
const common = @import("common.zig");
const printf = std.c.printf;

const shark = @import("shark.zig");
pub const SDL_WINDOW_FULLSCREEN: u64 = 1;
pub const SDL_WINDOW_HIDDEN: u64 = 8;

const atlas_img = @embedFile("atlas.png");
const title_img = @embedFile("title.png");
const water_img = @embedFile("water.png");

const GamePad = packed struct(u8) {
    @"1": bool,
    @"2": bool,
    _1: bool,
    _2: bool,
    left: bool,
    right: bool,
    up: bool,
    down: bool,
};
// var fbsdl: [common.SCREEN_SIZE * common.SCREEN_SIZE]u32 = @splat(0);
// var fb: [common.SCREEN_SIZE * common.SCREEN_SIZE]u2 = @splat(0);

fn import_img(ren: *sdl.Renderer, bytes: []const u8) !*sdl.Texture {
    const stream = try sdl.IOStream.fromConstMem(bytes.ptr, bytes.len);
    const surface = try sdl.loadPngIo(stream, true);
    const texture = try sdl.Texture.createFromSurface(ren, surface);
    surface.deinit();
    return texture;
}

pub export fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int {
    _ = argc;
    _ = argv;
    Main() catch |e| {
        _ = printf("%s\n", @errorName(e).ptr);
        while (DS.aptMainLoop()) {
            DS.gspWaitForEvent(DS.GSPGPU_EVENT_VBlank0, true);
            DS.gfxSwapBuffers();
        }
    };
    return 0;
}
const E = error{
    sdl,
};
fn Main() !void {
    try sdl.init(.{ .gamepad = true, .video = true });
    defer sdl.quit();
    const w = try sdl.createWindow("", 1, 1, SDL_WINDOW_FULLSCREEN | SDL_WINDOW_HIDDEN);
    defer sdl.destoryWindow(w);

    const ren = blk: {
        const prop = try sdl.Properties.init();
        defer prop.deinit();
        try prop.setNumber(C.SDL_PROP_RENDERER_CREATE_PRESENT_VSYNC_NUMBER, 1);
        try prop.setPointer(C.SDL_PROP_RENDERER_CREATE_WINDOW_POINTER, w);
        break :blk try sdl.Renderer.createWithProperties(prop);
    };
    defer ren.deinit();

    _ = DS.consoleInit(DS.GFX_BOTTOM, null);
    _ = std.c.printf("Hello\n");
    try ren.setLogicalPresentation(160, 160, .LETTERBOX);

    const tex_atlas = try import_img(ren, atlas_img);
    defer tex_atlas.deinit();
    try tex_atlas.setScaleMode(.pixelart);

    const tex_title = try import_img(ren, title_img);
    defer tex_title.deinit();
    try tex_title.setScaleMode(.pixelart);

    const tex_water = try import_img(ren, water_img);
    defer tex_water.deinit();
    try tex_water.setScaleMode(.pixelart);

    const gp = C.SDL_OpenGamepad(1);
    const gp1: *GamePad = @ptrCast(&common._gamepad1);

    // const full: C.SDL_Rect = .{ .x = 0, .y = 0, .w = 160, .h = 160 };
    main_loop: while (true) {
        var e: C.SDL_Event = undefined;
        while (C.SDL_PollEvent(&e)) {
            if (e.type == C.SDL_EVENT_QUIT) {
                break :main_loop;
            }
        }

        //WASM-4 update
        gp1.right = (C.SDL_GetGamepadButton(gp, C.SDL_GAMEPAD_BUTTON_DPAD_RIGHT));
        gp1.left = (C.SDL_GetGamepadButton(gp, C.SDL_GAMEPAD_BUTTON_DPAD_LEFT));
        gp1.@"1" = (C.SDL_GetGamepadButton(gp, C.SDL_GAMEPAD_BUTTON_LABEL_A));
        gp1.@"2" = (C.SDL_GetGamepadButton(gp, C.SDL_GAMEPAD_BUTTON_LABEL_B));

        //clear
        // for (&fb) |*b| {
        //     b.* = 0;
        // }
        // _ = printf("shark.update()\n");
        //update screen from common._fb
        // C.SDL_SetPaletteColors(palette: [*c]struct_SDL_Palette, colors: [*c]const struct_SDL_Color, firstcolor: c_int, ncolors: c_int)
        // for (fb, 0..) |b, i| {
        //     fbsdl[i] = common._palette[b];
        // }
        // fbsdl[0] = C.SDL_MapRGB(format_details, null, 255, 30, 30);
        // r = C.SDL_UpdateTexture(tex, &full, &fbsdl, 160 * 4);
        // if (!r) break;
        // var ticks: i64 = 0;
        // _ = C.SDL_GetCurrentTime(&ticks);
        // _ = printf("update %lu ns @ %lu\n", C.SDL_GetPerformanceCounter(), C.SDL_GetPerformanceFrequency());

        try ren.setDrawColor(0x59, 0x95, 0xd1, 255);
        try ren.clear();

        // try ren.setDrawColor(20, 20, 255, 255);
        // try ren.renderFillRect(&.{ .x = 0, .y = 0, .w = 30, .h = 40 });
        try shark.update(ren, tex_atlas, tex_title, tex_water);
        // ticks = C.SDL_GetTicksNS();
        // r = C.SDL_RenderTexture(ren, tex, null, null);
        // if (!r) break;

        // _ = printf("render %lu ns ", C.SDL_GetTicksNS() - ticks);

        // ticks = C.SDL_GetTicksNS();
        try ren.present();
        // _ = printf("present %lu ns\n", C.SDL_GetTicksNS() - ticks);
    }
    _ = std.c.printf("SDL Errr: %s\n", C.SDL_GetError());
}
