const std = @import("std");
// const sdlzig = @import("sdlzig");
const C = @cImport({
    @cInclude("SDL3/SDL.h");
});
const DS = @cImport({
    @cInclude("3ds.h");
});
const common = @import("common.zig");

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

pub export fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int {
    _ = argc;
    _ = argv;
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();
    var r: bool = undefined;
    r = C.SDL_Init(C.SDL_INIT_VIDEO | C.SDL_INIT_GAMEPAD);
    if (!r) {
        C.SDL_Log("Init Error! %s", C.SDL_GetError());
        return -1;
    }
    defer C.SDL_Quit();
    const w = SDL_CreateWindow("", 1, 1, SDL_WINDOW_FULLSCREEN | SDL_WINDOW_HIDDEN) orelse {
        C.SDL_Log("Init Error! %s", C.SDL_GetError());
        return -1;
    };
    defer C.SDL_DestroyWindow(w);
    defer C.SDL_Quit();

    const prop: u32 = C.SDL_CreateProperties();
    _ = C.SDL_SetBooleanProperty(prop, C.SDL_PROP_RENDERER_CREATE_PRESENT_VSYNC_NUMBER, true);
    _ = C.SDL_SetPointerProperty(prop, C.SDL_PROP_RENDERER_CREATE_WINDOW_POINTER, w);
    const ren = C.SDL_CreateRendererWithProperties(prop) orelse {
        C.SDL_Log("Init Error! %s", C.SDL_GetError());
        return -1;
    };
    _ = DS.consoleInit(DS.GFX_BOTTOM, null);
    _ = std.c.printf("Hello\n");
    C.SDL_DestroyProperties(prop);
    r = C.SDL_SetRenderLogicalPresentation(ren, 160, 160, C.SDL_LOGICAL_PRESENTATION_LETTERBOX);
    defer C.SDL_DestroyRenderer(ren);

    const tex = C.SDL_CreateTexture(ren, C.SDL_PIXELFORMAT_XRGB32, C.SDL_TEXTUREACCESS_STREAMING, 160, 160) orelse {
        C.SDL_Log("Init Error! %s", C.SDL_GetError());
        return -1;
    };
    defer C.SDL_DestroyTexture(tex);

    const gp = C.SDL_OpenGamepad(0);
    const gp1: *GamePad = @ptrCast(&common._gamepad1);

    //WASM-4 init
    var fb: [common.SCREEN_SIZE * common.SCREEN_SIZE]u2 = @splat(0);
    common._fb = &fb;
    var fbsdl: *[common.SCREEN_SIZE * common.SCREEN_SIZE]u32 = alloc.alloc(u32, common.SCREEN_SIZE * common.SCREEN_SIZE);
    defer alloc.free(fbsdl);

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

        shark.update();
        //update screen from common._fb
        //TODO this breaks it
        if (C.SDL_GetGamepadButton(gp, C.SDL_GAMEPAD_BUTTON_LABEL_X)) {
            for (fb, 0..) |b, i| {
                fbsdl[i] = common._palette[b];
            }
        }
        // const full: C.SDL_Rect = .{ .x = 0, .y = 0, .w = 160, .h = 160 };
        // r = C.SDL_UpdateTexture(tex, &full, &fbsdl, 160 * 4);
        // if (!r) break;

        // r = C.SDL_SetRenderDrawColor(ren, 20, 20, 20, 255);
        // if (!r) break;
        r = C.SDL_RenderClear(ren);
        // if (!r) break;
        r = C.SDL_RenderPresent(ren);
        // if (!r) break;
    }
    _ = std.c.printf("SDL Errr: %s\n", C.SDL_GetError());
    while (DS.aptMainLoop()) {
        DS.gspWaitForEvent(DS.GSPGPU_EVENT_VBlank0, true);
        DS.gfxSwapBuffers();
    }

    return 0;
}
