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

	D3D11.CreateDevice(nil, .HARDWARE, nil, {.BGRA_SUPPORT}, &feature_levels[0], len(feature_levels), D3D11.SDK_VERSION, &base_device, nil, &base_device_context)

	device: ^D3D11.IDevice
	base_device->QueryInterface(D3D11.IDevice_UUID, (^rawptr)(&device))

	device_context: ^D3D11.IDeviceContext
	base_device_context->QueryInterface(D3D11.IDeviceContext_UUID, (^rawptr)(&device_context))

	dxgi_device: ^DXGI.IDevice
	device->QueryInterface(DXGI.IDevice_UUID, (^rawptr)(&dxgi_device))

	dxgi_adapter: ^DXGI.IAdapter
	dxgi_device->GetAdapter(&dxgi_adapter)

	dxgi_factory: ^DXGI.IFactory2
	dxgi_adapter->GetParent(DXGI.IFactory2_UUID, (^rawptr)(&dxgi_factory))

	///////////////////////////////////////////////////////////////////////////////////////////////

	swapchain_desc := DXGI.SWAP_CHAIN_DESC1{
		Width  = 0,
		Height = 0,
		Format = .B8G8R8A8_UNORM_SRGB,
		Stereo = false,
		SampleDesc = {
			Count   = 1,
			Quality = 0,
		},
		BufferUsage = {.RENDER_TARGET_OUTPUT},
		BufferCount = 2,
		Scaling     = .STRETCH,
		SwapEffect  = .DISCARD,
		AlphaMode   = .UNSPECIFIED,
		Flags       = 0,
	}

	swapchain: ^DXGI.ISwapChain1
	dxgi_factory->CreateSwapChainForHwnd(device, native_window, &swapchain_desc, nil, nil, &swapchain)

	framebuffer: ^D3D11.ITexture2D
	swapchain->GetBuffer(0, D3D11.ITexture2D_UUID, (^rawptr)(&framebuffer))

	framebuffer_view: ^D3D11.IRenderTargetView
	device->CreateRenderTargetView(framebuffer, nil, &framebuffer_view)

	depth_buffer_desc: D3D11.TEXTURE2D_DESC
	framebuffer->GetDesc(&depth_buffer_desc)
	depth_buffer_desc.Format = .D24_UNORM_S8_UINT
	depth_buffer_desc.BindFlags = {.DEPTH_STENCIL}

	depth_buffer: ^D3D11.ITexture2D
	device->CreateTexture2D(&depth_buffer_desc, nil, &depth_buffer)

	depth_buffer_view: ^D3D11.IDepthStencilView
	device->CreateDepthStencilView(depth_buffer, nil, &depth_buffer_view)

	///////////////////////////////////////////////////////////////////////////////////////////////

	vs_blob: ^D3D11.IBlob
	D3D.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), "shaders.hlsl", nil, nil, "vs_main", "vs_5_0", 0, 0, &vs_blob, nil)
	assert(vs_blob != nil)

	vertex_shader: ^D3D11.IVertexShader
	device->CreateVertexShader(vs_blob->GetBufferPointer(), vs_blob->GetBufferSize(), nil, &vertex_shader)

	input_element_desc := [?]D3D11.INPUT_ELEMENT_DESC{
		{ "POS", 0, .R32G32B32_FLOAT, 0,                            0, .VERTEX_DATA, 0 },
		{ "NOR", 0, .R32G32B32_FLOAT, 0, D3D11.APPEND_ALIGNED_ELEMENT, .VERTEX_DATA, 0 },
		{ "TEX", 0, .R32G32_FLOAT,    0, D3D11.APPEND_ALIGNED_ELEMENT, .VERTEX_DATA, 0 },
		{ "COL", 0, .R32G32B32_FLOAT, 0, D3D11.APPEND_ALIGNED_ELEMENT, .VERTEX_DATA, 0 },
	}

	input_layout: ^D3D11.IInputLayout
	device->CreateInputLayout(&input_element_desc[0], len(input_element_desc), vs_blob->GetBufferPointer(), vs_blob->GetBufferSize(), &input_layout)

	ps_blob: ^D3D11.IBlob
	D3D.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), "shaders.hlsl", nil, nil, "ps_main", "ps_5_0", 0, 0, &ps_blob, nil)

	pixel_shader: ^D3D11.IPixelShader
	device->CreatePixelShader(ps_blob->GetBufferPointer(), ps_blob->GetBufferSize(), nil, &pixel_shader)

	///////////////////////////////////////////////////////////////////////////////////////////////

	rasterizer_desc := D3D11.RASTERIZER_DESC{
		FillMode = .SOLID,
		CullMode = .BACK,
	}
	rasterizer_state: ^D3D11.IRasterizerState
	device->CreateRasterizerState(&rasterizer_desc, &rasterizer_state)

	sampler_desc := D3D11.SAMPLER_DESC{
		Filter         = .MIN