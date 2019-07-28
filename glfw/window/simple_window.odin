package glfw_window

import "core:fmt"
import "vendor:glfw"
import gl "vendor:OpenGL"

WIDTH  	:: 1600
HEIGHT 	:: 900
TITLE 	:: "My Window!"

// @note You might need to lower this to 3.3 depending on how old your graphics card is.
GL_MAJOR_VERSION :: 4
GL_MIN