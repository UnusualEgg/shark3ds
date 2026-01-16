const C = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
});
pub const raw = C;

pub const Window = C.SDL_Window;
pub const Renderer = opaque {
    const Self = @This();

    extern fn SDL_RenderFillRect(renderer: ?*Renderer, rect: *const FRect) bool;
    pub fn renderFillRect(self: *Self, rect: FRect) !void {
        return wrapBool(SDL_RenderFillRect(self, rect));
    }
    extern fn SDL_RenderTexture(renderer: *Renderer, texture: *Texture, srcrect: *const FRect, dstrect: *const FRect) bool;
    pub fn renderTexture(renderer: *Renderer, texture: *Texture, srcrect: FRect, dstrect: FRect) !void {
        return wrapBool(SDL_RenderTexture(renderer, texture, srcrect, dstrect));
    }
};
pub const Surface = C.SDL_Surface;
pub const Texture = C.SDL_Texture;
pub const IOStream = C.SDL_IOStream;
pub const Color = extern struct { r: u8, g: u8, b: u8, a: u8 };
pub const FRect = C.SDL_FRect;

inline fn wrap(ret: anytype) error{sdl}!@typeInfo(@TypeOf(ret)).optional.child {
    if (@typeInfo(ret) != .optional) @compileError("ret should be optional");
    return ret orelse {
        C.SDL_Log("Init Error! %s", C.SDL_GetError());
        return error.sdl;
    };
}
inline fn wrapBool(ret: bool) error{sdl}!void {
    if (ret) {
        C.SDL_Log("Init Error! %s", C.SDL_GetError());
        return error.sdl;
    }
}

extern fn SDL_CreateWindow(title: [*:0]const u8, w: c_int, h: c_int, flags: u64) ?*C.SDL_Window;
pub fn createWindow(title: [*:0]const u8, w: c_int, h: c_int, flags: u64) !*C.SDL_Window {
    return wrap(SDL_CreateWindow(title, w, h, flags));
}
extern fn SDL_CreateTextureFromSurface(renderer: *Renderer, surface: *Surface) ?*Texture;
pub fn createTextureFromSurface(renderer: *Renderer, surface: *Surface) !*Texture {
    return wrap(SDL_CreateTextureFromSurface(renderer, surface));
}
extern fn SDL_LoadPNG_IO(src: *IOStream, closeio: bool) ?*Surface;
pub fn loadPngIo(src: *IOStream, closeio: bool) !*Surface {
    return wrap(SDL_LoadPNG_IO(src, closeio));
}

extern fn SDL_IOFromConstMem(mem: *const anyopaque, size: usize) ?*IOStream;
pub fn IoFromConstMem(mem: *const anyopaque, size: usize) !*IOStream {
    return wrap(SDL_IOFromConstMem(mem, size));
}

const ScaleMode = enum(c_int) {
    nearest = 0,
    linear = 1,
    pixelart = 2,
};
extern fn SDL_SetTextureScaleMode(texture: *Texture, scale_mode: ScaleMode) bool;
pub fn setTextureScaleMode(texture: *Texture, scale_mode: ScaleMode) !void {
    return wrapBool(SDL_SetTextureScaleMode(texture, scale_mode));
}

extern fn SDL_DestroySurface(surface: *Surface) void;
pub const destorySurface = SDL_DestroySurface;
extern fn SDL_DestroyTexture(texture: *Texture) void;
pub const destroyTexture = SDL_DestroyTexture;

extern fn SDL_Quit() void;
pub fn quit() void {
    SDL_Quit();
}
