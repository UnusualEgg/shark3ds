const std = @import("std");
// const sdlzig = @import("sdlzig");
const C = @cImport({
    @cInclude("SDL3/SDL.h");
});
const DS = @cImport({
    @cInclude("3ds.h");
});
const common = @import("common.zig");
const printf = std.c.printf;

const shark = @import("shark.zig");
pub extern fn SDL_CreateWindow(title: [*c]const u8, w: c_int, h: c_int, flags: u64) ?*C.SDL_Window;
pub const SDL_WINDOW_FULLSCREEN: u64 = 1;
pub const SDL_WINDOW_HIDDEN: u64 = 8;

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
var fbsdl: [common.SCREEN_SIZE * common.SCREEN_SIZE]u32 = @splat(0);
var fb: [common.SCREEN_SIZE * common.SCREEN_SIZE]u2 = @splat(0);

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
    var r: bool = undefined;
    r = C.SDL_Init(C.SDL_INIT_VIDEO | C.SDL_INIT_GAMEPAD);
    if (!r) {
        C.SDL_Log("Init Error! %s", C.SDL_GetError());
        return E.sdl;
    }
    defer C.SDL_Quit();
    const w = SDL_CreateWindow("", 1, 1, SDL_WINDOW_FULLSCREEN | SDL_WINDOW_HIDDEN) orelse {
        C.SDL_Log("Init Error! %s", C.SDL_GetError());
        return E.sdl;
    };
    defer C.SDL_DestroyWindow(w);
    defer C.SDL_Quit();

    const prop: u32 = C.SDL_CreateProperties();
    _ = C.SDL_SetBooleanProperty(prop, C.SDL_PROP_RENDERER_CREATE_PRESENT_VSYNC_NUMBER, true);
    _ = C.SDL_SetPointerProperty(prop, C.SDL_PROP_RENDERER_CREATE_WINDOW_POINTER, w);
    const ren = C.SDL_CreateRendererWithProperties(prop) orelse {
        C.SDL_Log("Init Error! %s", C.SDL_GetError());
        return E.sdl;
    };
    _ = DS.consoleInit(DS.GFX_BOTTOM, null);
    _ = std.c.printf("Hello\n");
    C.SDL_DestroyProperties(prop);
    r = C.SDL_SetRenderLogicalPresentation(ren, 160, 160, C.SDL_LOGICAL_PRESENTATION_LETTERBOX);
    defer C.SDL_DestroyRenderer(ren);

    const FORMAT = C.SDL_PIXELFORMAT_XRGB32;
    const tex = C.SDL_CreateTexture(ren, FORMAT, C.SDL_TEXTUREACCESS_STREAMING, 160, 160) orelse {
        C.SDL_Log("Init Error! %s", C.SDL_GetError());
        return E.sdl;
    };
    defer C.SDL_DestroyTexture(tex);
    r = C.SDL_SetTextureScaleMode(tex, C.SDL_SCALEMODE_NEAREST);
    if (!r) {
        C.SDL_Log("texutre scale mode error: %s", C.SDL_GetError());
        return E.sdl;
    }

    const format_details = C.SDL_GetPixelFormatDetails(FORMAT);

    const gp = C.SDL_OpenGamepad(1);
    const gp1: *GamePad = @ptrCast(&common._gamepad1);

    //WASM-4 init
    //0x5995d1, //sky blue (light)
    //0xffffff, //white
    //0x1d456d, //water blue (dark)
    //0x58dd58, //green
    common._palette[0] = C.SDL_MapRGB(format_details, null, 0x59, 0x95, 0xd1);
    common._palette[1] = C.SDL_MapRGB(format_details, null, 0xff, 0xff, 0xff);
    common._palette[2] = C.SDL_MapRGB(format_details, null, 0x1d, 0x45, 0x6d);
    common._palette[3] = C.SDL_MapRGB(format_details, null, 0x58, 0xdd, 0x58);
    common._fb = &fb;

    shark.start();

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
        for (&fb) |*b| {
            b.* = 0;
        }
        // _ = printf("shark.update()\n");
        shark.update();
        //update screen from common._fb
        //TODO this breaks it
        // if (C.SDL_GetGamepadButton(gp, C.SDL_GAMEPAD_BUTTON_LABEL_X)) {
        for (fb, 0..) |b, i| {
            fbsdl[i] = common._palette[b];
        }
        fbsdl[0] = C.SDL_MapRGB(format_details, null, 255, 30, 30);
        // }
        const full: C.SDL_Rect = .{ .x = 0, .y = 0, .w = 160, .h = 160 };
        r = C.SDL_UpdateTexture(tex, &full, &fbsdl, 160 * 4);
        if (!r) break;

        r = C.SDL_SetRenderDrawColor(ren, 20, 20, 20, 255);
        if (!r) break;
        r = C.SDL_RenderClear(ren);
        if (!r) break;

        r = C.SDL_RenderTexture(ren, tex, null, null);
        if (!r) break;

        r = C.SDL_RenderPresent(ren);
        if (!r) break;
    }
    _ = std.c.printf("SDL Errr: %s\n", C.SDL_GetError());
}
