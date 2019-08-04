package glfw_window

import "core:fmt"
import "vendor:glfw"
import gl "vendor:OpenGL"

WIDTH  	:: 1600
HEIGHT 	:: 900
TITLE 	:: "My Window!"

// @note You might need to lower this to 3.3 depending on how old your graphics card is.
GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

main :: proc() {
	if !bool(glfw.Init()) {
		fmt.eprintln("GLFW has failed to load.")
		return
	}

	window_handle := glfw.CreateWindow(WIDTH, HEIGHT, TITLE, nil, nil)

	defer glfw.Terminate()
	defer glfw.DestroyWindow(window_handle)

	if window_handle == nil {
		fmt.eprintln("GLFW has failed to load the window.")
		return
	}

	// Load OpenGL context or the "state" of OpenGL.
	glfw.MakeContextCurrent(window_handle)
	// Load OpenGL function pointers with the