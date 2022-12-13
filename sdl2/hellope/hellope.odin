
/*
	SDL2 example for Odin.

	`SDL2.dll` needs to be available.
	If `USE_SDL2_IMAGE` is enabled, `SDL2_image.dll` and `libpng16-16.dll` also need to be present.

	On Windows this means placing them next to the executable.

	This example code is available as a Public Domain reference under the Unlicense (https://unlicense.org/),
	or under Odin's BSD-3 license. Choose whichever you prefer.
*/

package hellope

import "vendor:sdl2"
import "core:log"
import "core:os"
import core_img "core:image"
import "core:math"

USE_SDL2_IMAGE :: #config(USE_SDL2_IMAGE, false)

when USE_SDL2_IMAGE {
	import "core:strings"
	import sdl_img "vendor:sdl2/image"
} else {
	import "core:image/png"
}

WINDOW_TITLE  :: "Hellope World!"
WINDOW_X      := i32(400)
WINDOW_Y      := i32(400)
WINDOW_WIDTH  := i32(800)
WINDOW_HEIGHT := i32(600)
WINDOW_FLAGS  :: sdl2.WindowFlags{.SHOWN}

/*
	If `true`, center the window using the desktop extents of the primary adapter.
	If `false`, position at WINDOW_X, WINDOW_Y.
*/
CENTER_WINDOW :: true

/*
	Relative path to Odin logo
*/
ODIN_LOGO_PATH :: "logo-slim.png"

Texture_Asset :: struct {
	tex: ^sdl2.Texture,
	w:   i32,
	h:   i32,

	scale: f32,
	pivot: struct {
		x: f32,
		y: f32,
	},
}

Surface :: struct {
	surf: ^sdl2.Surface,
	/*
		If using `core:image/png`, `img` will hold the pointer to the `Image` returned by `png.load`.
		Unused when `USE_SDL2_IMAGE` is enabled.
	*/
	img:  ^core_img.Image,
}

CTX :: struct {
	window:        ^sdl2.Window,
	surface:       ^sdl2.Surface,
	renderer:      ^sdl2.Renderer,
	textures:      [dynamic]Texture_Asset, 

	should_close:  bool,
	app_start:     f64,

	frame_start:   f64,
	frame_end:     f64,
	frame_elapsed: f64,

}

ctx := CTX{}

init_sdl :: proc() -> (ok: bool) {
	if sdl_res := sdl2.Init(sdl2.INIT_VIDEO); sdl_res < 0 {
		log.errorf("sdl2.init returned %v.", sdl_res)
		return false
	}

	when USE_SDL2_IMAGE {
		img_init_flags := sdl_img.INIT_PNG
		img_res        := sdl_img.InitFlags(sdl_img.Init(img_init_flags))
		if img_init_flags != img_res {
			log.errorf("sdl2_image.init returned %v.", img_res)
		}
	}

	if CENTER_WINDOW {
		/*
			Get desktop bounds for primary adapter
		*/
		bounds := sdl2.Rect{}
		if e := sdl2.GetDisplayBounds(0, &bounds); e != 0 {
			log.errorf("Unable to get desktop bounds.")
			return false
		}

		WINDOW_X = ((bounds.w - bounds.x) / 2) - (WINDOW_WIDTH  / 2) + bounds.x
		WINDOW_Y = ((bounds.h - bounds.y) / 2) - (WINDOW_HEIGHT / 2) + bounds.y
	}

	ctx.window = sdl2.CreateWindow(WINDOW_TITLE, WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_FLAGS)
	if ctx.window == nil {
		log.errorf("sdl2.CreateWindow failed.")
		return false
	}

	ctx.renderer = sdl2.CreateRenderer(ctx.window, -1, {.ACCELERATED, .PRESENTVSYNC})
	if ctx.renderer == nil {
		log.errorf("sdl2.CreateRenderer failed.")
		return false
	}

	return true
}

when USE_SDL2_IMAGE { 
	load_surface_from_image_file :: proc(image_path: string) -> (surface: ^Surface) {
		path := strings.clone_to_cstring(image_path, context.temp_allocator)

		surface = new(Surface)
		surface.surf = sdl_img.Load(path)
		if surface.surf == nil {
			log.errorf("Couldn't load %v.", ODIN_LOGO_PATH)
		}
		return
	}
} else {
	load_surface_from_image_file :: proc(image_path: string) -> (surface: ^Surface) {

		/*
			Load PNG using `core:image/png`.
		*/
		res_img, res_error := png.load(image_path)
		if res_error != nil {
			log.errorf("Couldn't load %v.", ODIN_LOGO_PATH)
			return nil
		}

		surface = new(Surface)
		surface.img = res_img

		/*