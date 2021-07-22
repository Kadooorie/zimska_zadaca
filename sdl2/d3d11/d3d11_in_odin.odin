package d3d11_test

import D3D11 "vendor:directx/d3d11"
import DXGI "vendor:directx/dxgi"
import D3D "vendor:directx/d3d_compiler"
import SDL "vendor:sdl2"
import glm "core:math/linalg/glsl"

// Based off https://gist.github.com/d7samurai/261c69490cce0620d0bfc93003cd1052

main :: proc() {
	SDL.Init({.VIDEO})
	defer SDL.Quit()

	SDL.SetHintWithPriority(SDL.HINT_RENDER_DRIVER, "direct3d11", .OVERRIDE)
	window := SDL.CreateWindow("D3D11 in Odin",
		SDL.WINDOWPOS_CENTERED, SDL.WINDOWPOS_CENTERED,
		854, 480,
		{.ALLOW_HIGHDPI, .HIDDEN, .RESIZABLE},
	)
	defer SDL.DestroyWindow(window)

	window_system_info: SDL.SysWMinfo
	SDL.GetVersion(&window_system_info.version)
	SDL.GetWindowWMInfo(window, &window_system_info)
	assert(window_system_info.subsystem == .WINDOWS)

	native_window := DXGI.HWND(window_system_info.info.win.window)

	feature_levels := [?]D3D11.FEATURE_LEVEL{._11_0}

	base_device: ^D3D11.IDevice
	base_device_context: ^D3D11.IDeviceContext

	D3D11.CreateDevice(nil, .HARDWARE, 