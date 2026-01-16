const C = @cImport({
    @cInclude("SDL3/SDL.h");
});
pub const raw = C;

pub const PixelFormat = enum(c_uint) {
    UNKNOWN = 0,
    INDEX1LSB = 286261504,
    INDEX1MSB = 287310080,
    INDEX2LSB = 470811136,
    INDEX2MSB = 471859712,
    INDEX4LSB = 303039488,
    INDEX4MSB = 304088064,
    INDEX8 = 318769153,
    RGB332 = 336660481,
    XRGB4444 = 353504258,
    XBGR4444 = 357698562,
    XRGB1555 = 353570562,
    XBGR1555 = 357764866,
    ARGB4444 = 355602434,
    RGBA4444 = 356651010,
    ABGR4444 = 359796738,
    BGRA4444 = 360845314,
    ARGB1555 = 355667970,
    RGBA5551 = 356782082,
    ABGR1555 = 359862274,
    BGRA5551 = 360976386,
    RGB565 = 353701890,
    BGR565 = 357896194,
    RGB24 = 386930691,
    BGR24 = 390076419,
    XRGB8888 = 370546692,
    RGBX8888 = 371595268,
    XBGR8888 = 374740996,
    BGRX8888 = 375789572,
    ARGB8888 = 372645892,
    RGBA8888 = 373694468,
    // ABGR8888 = 376840196,
    // BGRA8888 = 377888772,
    // XRGB2101010 = 370614276,
    // XBGR2101010 = 374808580,
    // ARGB2101010 = 372711428,
    // ABGR2101010 = 376905732,
    // RGB48 = 403714054,
    // BGR48 = 406859782,
    // RGBA64 = 404766728,
    // ARGB64 = 405815304,
    // BGRA64 = 407912456,
    // ABGR64 = 408961032,
    // RGB48_FLOAT = 437268486,
    // BGR48_FLOAT = 440414214,
    // RGBA64_FLOAT = 438321160,
    // ARGB64_FLOAT = 439369736,
    // BGRA64_FLOAT = 441466888,
    // ABGR64_FLOAT = 442515464,
    // RGB96_FLOAT = 454057996,
    // BGR96_FLOAT = 457203724,
    // RGBA128_FLOAT = 455114768,
    // ARGB128_FLOAT = 456163344,
    // BGRA128_FLOAT = 458260496,
    // ABGR128_FLOAT = 459309072,
    // YV12 = 842094169,
    // IYUV = 1448433993,
    // YUY2 = 844715353,
    // UYVY = 1498831189,
    // YVYU = 1431918169,
    // NV12 = 842094158,
    // NV21 = 825382478,
    // P010 = 808530000,
    // EXTERNAL_OES = 542328143,
    // MJPG = 1196444237,
    // RGBA32 = 376840196,
    // ARGB32 = 377888772,
    // BGRA32 = 372645892,
    // ABGR32 = 373694468,
    // RGBX32 = 374740996,
    // XRGB32 = 375789572,
    // BGRX32 = 370546692,
    // XBGR32 = 371595268,
};
pub const Window = C.SDL_Window;
pub const Renderer = opaque {
    const Self = @This();

    extern fn SDL_CreateRendererWithProperties(props: PropertiesID) ?*Renderer;
    pub fn createWithProperties(props: Properties) !*Renderer {
        return wrap(*Renderer, SDL_CreateRendererWithProperties(props.id));
    }
    extern fn SDL_DestroyRenderer(renderer: *Renderer) void;
    pub const deinit = SDL_DestroyRenderer;

    extern fn SDL_SetRenderDrawColor(renderer: *Renderer, r: u8, g: u8, b: u8, a: u8) bool;
    pub fn setDrawColor(self: *Self, r: u8, g: u8, b: u8, a: u8) !void {
        return wrapBool(SDL_SetRenderDrawColor(self, r, g, b, a));
    }

    extern fn SDL_RenderFillRect(renderer: ?*Renderer, rect: *const FRect) bool;
    pub fn renderFillRect(self: *Self, rect: FRect) !void {
        return wrapBool(SDL_RenderFillRect(self, rect));
    }
    extern fn SDL_RenderTexture(renderer: *Renderer, texture: *Texture, srcrect: ?*const FRect, dstrect: ?*const FRect) bool;
    pub fn renderTexture(self: *Self, texture: *Texture, srcrect: ?*FRect, dstrect: ?*FRect) !void {
        return wrapBool(SDL_RenderTexture(self, texture, srcrect, dstrect));
    }

    extern fn SDL_RenderTextureRotated(
        renderer: *Renderer,
        texture: *Texture,
        srcrect: *const FRect,
        dstrect: *const FRect,
        angle: f64,
        center: *const FPoint,
        flip: FlipMode,
    ) bool;
    pub fn renderTextureRotated(
        self: *Self,
        texture: *Texture,
        srcrect: ?*const FRect,
        dstrect: ?*const FRect,
        angle: f64,
        center: FPoint,
        flip: FlipMode,
    ) !void {
        return wrapBool(SDL_RenderTextureRotated(self, texture, srcrect, dstrect, angle, center, flip));
    }

    extern fn SDL_RenderPresent(renderer: *Renderer) bool;
    pub fn present(self: *Self) !void {
        return wrapBool(SDL_RenderPresent(self));
    }
    extern fn SDL_SetRenderLogicalPresentation(renderer: *Renderer, w: c_int, h: c_int, mode: LogicalPresentation) bool;
    pub fn setLogicalPresentation(self: *Self, w: c_int, h: c_int, mode: LogicalPresentation) !void {
        return wrapBool(SDL_SetRenderLogicalPresentation(self, w, h, mode));
    }
};
pub const LogicalPresentation = enum(c_uint) {
    DISABLED = 0,
    STRETCH = 1,
    LETTERBOX = 2,
    OVERSCAN = 3,
    INTEGER_SCALE = 4,
};
pub const FlipMode = enum(c_uint) {
    NONE = 0,
    HORIZONTAL = 1,
    VERTICAL = 2,
    HORIZONTAL_AND_VERTICAL = 3,
};
pub const PropertiesID = u32;
pub const Properties = struct {
    const Self = @This();
    id: PropertiesID,
    extern fn SDL_CreateProperties() PropertiesID;
    pub fn init() !Self {
        return Self{ .id = try wrapInt(SDL_CreateProperties()) };
    }
    extern fn SDL_DestroyProperties(props: PropertiesID) void;
    pub fn deinit(self: Self) void {
        SDL_DestroyProperties(self.id);
    }
    extern fn SDL_SetBooleanProperty(props: PropertiesID, name: [*:0]const u8, value: bool) bool;
    pub fn setBoolean(self: Self, name: [*:0]const u8, boolean: bool) !void {
        return wrapBool(SDL_SetBooleanProperty(self.id, name, boolean));
    }
    extern fn SDL_SetNumberProperty(props: PropertiesID, name: [*:0]const u8, value: i64) bool;
    pub fn setNumber(self: Self, name: [*:0]const u8, number: i64) !void {
        return wrapBool(SDL_SetNumberProperty(self.id, name, number));
    }
    extern fn SDL_SetPointerProperty(props: PropertiesID, name: [*:0]const u8, value: ?*anyopaque) bool;
    pub fn setPointer(self: Self, name: [*:0]const u8, pointer: ?*anyopaque) !void {
        return wrapBool(SDL_SetPointerProperty(self.id, name, pointer));
    }
};

pub const Surface = extern struct {
    flags: C.SDL_SurfaceFlags,
    format: PixelFormat,
    w: c_int,
    h: c_int,
    pitch: c_int,
    pixels: ?*anyopaque,
    refcount: c_int,
    reserved: ?*anyopaque,

    extern fn SDL_DestroySurface(surface: *Surface) void;
    pub const deinit = SDL_DestroySurface;
};
pub const Texture = extern struct {
    format: PixelFormat,
    w: c_int,
    h: c_int,
    refcount: c_int,

    extern fn SDL_DestroyTexture(texture: *Texture) void;
    pub const deinit = SDL_DestroyTexture;
    extern fn SDL_SetTextureScaleMode(texture: *Texture, scale_mode: ScaleMode) bool;
    pub fn setScaleMode(texture: *Texture, scale_mode: ScaleMode) !void {
        return wrapBool(SDL_SetTextureScaleMode(texture, scale_mode));
    }
    extern fn SDL_CreateTextureFromSurface(renderer: *Renderer, surface: *Surface) ?*Texture;
    /// doesn't free surface
    pub fn createFromSurface(renderer: *Renderer, surface: *Surface) !*Texture {
        return wrap(SDL_CreateTextureFromSurface(renderer, surface));
    }
};
pub const IOStream = opaque {
    extern fn SDL_IOFromConstMem(mem: *const anyopaque, size: usize) ?*IOStream;
    pub fn fromConstMem(mem: *const anyopaque, size: usize) !*IOStream {
        return wrap(SDL_IOFromConstMem(mem, size));
    }
};
pub const Color = extern struct { r: u8, g: u8, b: u8, a: u8 };
pub const FRect = C.SDL_FRect;
pub const FPoint = C.SDL_FPoint;

inline fn wrap(T: type, ret: ?T) error{sdl}!T {
    return ret orelse {
        C.SDL_Log("SDL Error! %s", C.SDL_GetError());
        return error.sdl;
    };
}
inline fn wrapBool(ret: bool) error{sdl}!void {
    if (ret) {
        C.SDL_Log("SDL Error! %s", C.SDL_GetError());
        return error.sdl;
    }
}
inline fn wrapInt(ret: u32) error{sdl}!u32 {
    if (ret == 0) {
        C.SDL_Log("SDL Error! %s", C.SDL_GetError());
        return error.sdl;
    }
    return ret;
}

extern fn SDL_CreateWindow(title: [*:0]const u8, w: c_int, h: c_int, flags: u64) ?*Window;
pub fn createWindow(title: [*:0]const u8, w: c_int, h: c_int, flags: u64) !*Window {
    return wrap(*Window, SDL_CreateWindow(title, w, h, flags));
}
extern fn SDL_DestroyWindow(window: *Window) void;
pub const destoryWindow = SDL_DestroyWindow;

extern fn SDL_LoadPNG_IO(src: *IOStream, closeio: bool) ?*Surface;
pub fn loadPngIo(src: *IOStream, closeio: bool) !*Surface {
    return wrap(*Surface, SDL_LoadPNG_IO(src, closeio));
}

const ScaleMode = enum(c_int) {
    nearest = 0,
    linear = 1,
    pixelart = 2,
};

extern fn SDL_Quit() void;
pub fn quit() void {
    SDL_Quit();
}
