
package main

import NS "vendor:darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA "vendor:darwin/QuartzCore"

import SDL "vendor:sdl2"

import "core:fmt"
import "core:os"
import "core:math"


Instance_Data :: struct #align 16 {
	transform: matrix[4, 4]f32,
	color:     [4]f32,
}

NUM_INSTANCES :: 32