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
		SDL.WINDOWPOS_CENTERED, SDL.WINDOWPOS_CENTERED, 
		854, 480, 
		SDL.WINDOW_ALLOW_HIGHDPI|SDL.WINDOW_HIDDEN,
	)
	defer SDL.DestroyWindow(window)

	window_system_info: SDL.SysWMinfo
	SDL.GetVersion(&window_system_info.version)
	SDL.GetWindowWMInfo(window, &window_system_info)
	assert(window_system_info.subsystem == .COCOA)
	fmt.println(window_system_info)

	sw