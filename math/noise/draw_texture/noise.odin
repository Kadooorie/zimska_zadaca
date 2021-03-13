
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
	3 - x + width, y + height

	0      2
	|-----/|
	|   /  |
	|  /   |
	|/-----|
	1      3

	**/

	vertices: Vertices = {
		x, y,                   0.0, 1.0,
		x, y + height,          0.0, 0.0,
		x + width, y,           1.0, 1.0,
		x + width, y + height,  1.0, 0.0,
	}

	return vertices
}


WAVELENGTH :: 120
Pixel :: [4]u8

noise_at :: proc(seed: i64, x, y: int) -> f32 {
	return (noise.noise_2d(seed, {f64(x) / 120, f64(y) / 120}) + 1.0) / 2.0
}

create_texture_noise :: proc(texture_id: u32, adjust_noise: Adjust_Noise) {

	texture_data := make([]u8, WIDTH * HEIGHT * 4)
	defer delete(texture_data)

	gl.BindTexture(gl.TEXTURE_2D, texture_id)
	gl.ActiveTexture(gl.TEXTURE0)

	gradient_location: glsl.vec2 = {f32(WIDTH / 2), f32(HEIGHT / 2)}

	pixels := mem.slice_data_cast([]Pixel, texture_data)

	for x := 0; x < WIDTH; x += 1 {

		for y := 0; y < HEIGHT; y += 1 {

			using adjust_noise := adjust_noise

			noise_val: f32

			{

				for i := 0; i < int(octaves); i += 1 {
					noise_val += 0.4 * ((noise.noise_2d(seed, {f64(x) / frequency / 2, f64(y) / frequency / 2}) + 1.0) / 2.0)
					noise_val += 0.6 * ((noise.noise_2d(seed, {f64(x) / frequency * 2 ,f64(y) / frequency * 2}) + 1.0) / 2.0)
					frequency *= glsl.exp(frequency)
				}
				noise_val /= f32(octaves)
			}

			val := glsl.distance_vec2({f32(x), f32(y)}, gradient_location)
			val /= f32(HEIGHT / 2)

			noise_val = noise_val - val

			if noise_val < 0.0 {
				noise_val = 0
			}

			val = glsl.clamp(val, 0.0, 1.0)
			color := u8((noise_val) * 255.0)

			switch {
			case color <  20:
				// Water
				noise_val =  0.75 + 0.25 * noise_at(seed, x, y)
				pixels[0] = {u8( 51 * noise_val), u8( 81 * noise_val), u8(251 * noise_val), 255}

			case color <  30:
				// Sand
				noise_val = 0.75 + 0.25 * noise_at(seed, x, y)
				pixels[0] = {u8(251 * noise_val), u8(244 * noise_val), u8(189 * noise_val), 255}

			case color <  60:
				// Grass
				noise_val = 0.75 + 0.25 * noise_at(seed, x, y)
				pixels[0] = {u8(124 * noise_val), u8(200 * noise_val), u8( 65 * noise_val), 255}

			case color <  90:
				// The forest
				noise_val = 0.75 + 0.25 * noise_at(seed, x, y)
				pixels[0] = {u8(124 * noise_val), u8(150 * noise_val), u8( 65 * noise_val), 255}

			case color < 120:
				// The Mountain
				noise_val = 0.7 + 0.2 * noise_at(seed, x, y)
				noise_val = glsl.pow(noise_val, 2)

				pixels[0] = {u8(143 * noise_val), u8(143 * noise_val), u8(143 * noise_val), 255}

			case:
				// The peak of the mountain
				noise_val = 0.7 + 0.2 * noise_at(seed, x, y)
				noise_val = glsl.pow(noise_val, 2)

				pixels[0] = {u8(205 * noise_val), u8(221 * noise_val), u8(246 * noise_val), 255}
			}
			pixels = pixels[1:]
		}
	}

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(WIDTH), i32(HEIGHT), 0, gl.RGBA, gl.UNSIGNED_BYTE, &texture_data[0])
}

main :: proc() {

	if !bool(glfw.Init()) {
		fmt.println("GLFW has failed to load.")
		return
	}

	glfw.SetErrorCallback(proc "c" (error: c.int, description: cstring) {