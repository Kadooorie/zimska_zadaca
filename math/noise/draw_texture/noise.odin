
package draw_texture

import "core:fmt"
import "core:math/linalg/glsl"
import "core:math/noise"
import gl "vendor:OpenGL"
import "vendor:glfw"
import "core:mem"
import "core:c"
import "core:runtime"

WIDTH  :: 400
HEIGHT :: 400
TITLE  :: cstring("Open Simplex 2 Texture!")

// @note You might need to lower this to 3.3 depending on how old your graphics card is.
GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 1

Adjust_Noise :: struct {
	seed:       i64,
	octaves:    i32,
	frequency: f64,
}

Vertices :: [16]f32

create_vertices :: proc(x, y, width, height: f32) -> Vertices {

	/**

	0 - x,y
	1 - x, y + height
	2 - x + width, y