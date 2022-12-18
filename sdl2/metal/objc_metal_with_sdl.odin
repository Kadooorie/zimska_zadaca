package objc_test

import NS "core:sys/darwin/Foundation"
import MTL "core:sys/darwin/Metal"
import CA "core:sys/darwin/QuartzCore"
	
import SDL "vendor:sdl2"

import "core:fmt"

main :: proc() {
	SDL.SetHint(SDL.HINT_RENDER_DRIVER, "metal")
	SDL.setenv("METAL_DEVICE_WRAPPER_TYPE", "1", 0)
	SDL.Init({.VIDEO})
	defer SDL.Quit()

	window := SDL.CreateWindow("SDL Metal", 
		SDL.WINDOWPOS_CENTERED, SDL.WINDOWPOS_CE