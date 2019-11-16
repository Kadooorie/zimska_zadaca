
package main

import NS "vendor:darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA "vendor:darwin/QuartzCore"

import SDL "vendor:sdl2"

import "core:fmt"
import "core:os"
import "core:math"
import glm "core:math/linalg/glsl"


Instance_Data :: struct #align 16 {
	transform: glm.mat4,
	color:     glm.vec4,
}

NUM_INSTANCES :: 32

Camera_Data :: struct {
	perspective_transform: glm.mat4,