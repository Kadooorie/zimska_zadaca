
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