
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
