package main

import NS "vendor:darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA "vendor:darwin/QuartzCore"

import SDL "vendor:sdl2"

import "core:fmt"
import "core:os"
import "core:math"
import glm "core:math/linalg/glsl"


Vertex_Data :: struct {
	position: glm.vec3,
	normal:   glm.vec3,
}

Instance_Data :: struct #align 16 {
	transform:        glm.mat4,
	color:            glm.vec4,
	normal_transform: glm.mat3,
}

INSTANCE_WIDTH  :: 10
INSTANCE_HEIGHT :: 10
INSTANCE_DEPTH  :: 10
NUM_INSTANCES   :: INSTANCE_WIDTH*INSTANCE_HEIGHT*INSTANCE_DEPTH

Camera_Data :: struct #align 16 {
	perspective_transform:  glm.mat4,
	world_transform:        glm.mat4,
	world_normal_transform: glm.mat3,
}

build_shaders :: proc(device: ^MTL.Device) -> (library: ^MTL.Library, pso: ^MTL.RenderPipelineState, err: ^NS.Error) {
	shader_src := `
	#include <metal_stdlib>
	using namespace metal;

	struct v2f {
		float4 position [[position]];
		float3 normal;
		half3 color;
	};

	struct Vertex_Data {
		packed_float3 position;
		packed_float3 normal;
	};

	struct Instance_Data {
		float4x4 transform;
		float4   color;
		float3x3 normal_transform;
	};

	struct Camera_Data {
		float4x4 perspective_transform;
		float4x4 world_transform;
		float3x3 world_normal_transform;
	};

	v2f vertex vertex_main(device const Vertex_Data*   vertex_data   [[buffer(0)]],
	                       device const Instance_Data* instance_data [[buffer(1)]],
	                       device const Camera_Data&   camera_data   [[buffer(2)]],
	                       uint vertex_id                            [[vertex_id]],
	                       uint instance_id                          [[instance_id]]) {
		v2f o;

		const device Vertex_Data&   vd = vertex_data[vertex_id];
		const device Instance_Data& id = instance_data[instance_id];

		float4 pos = float4(vd.position, 1.0);
		pos = id.transform * pos;
		pos = camera_data.perspective_transform * camera_data.world_transform * pos;
		o.position = pos;

		float3 normal = id.normal_transform * float3(vd.normal);
		normal   = camera_data.world_normal_transform * normal;
		o.normal = normal;

		o.color = half3(id.color.rgb);
		return o;
	}

	half4 fragment fragment_main(v2f in [[stage_in]]) {
		// assume light coming from front-top-right
		float3 l = normalize(float3(1.0, 1.0, 0.8));
		float3 n = normalize(in.normal);

		float ndotl = saturate(dot(n, l));

		return half4(in.color * 0.1 + in.color * ndotl, 1.0);
	}
	`
	shader_src_str := NS.String.alloc()->initWithOdinString(shader_src)
	defer shader_src_str->release()

	library = device->newLibraryWithSource(shader_src_str, nil) or_return

	vertex_function   := library->newFunctionWithName(NS.AT("vertex_main"))
	fragment_function := library->newFunctionWithName(NS.AT("fragment_main"))
	defer vertex_function->release()
	defer fragment_function->release()

	desc := MTL.RenderPipelineDescriptor.alloc()->init()
	defer desc->release()

	desc->setVertexFunction(vertex_function)
	desc->setFragmentFunction(fragment_function)
	desc->colorAttachments()->object(0)->setPixelFormat(.BGRA8Unorm_sRGB)
	desc->setDepthAttachmentPixelFormat(.Depth16Unorm)

	pso = device->newRenderPipelineStateWithDescriptor(desc) or_return
	return
}

build_buffers :: proc(device: ^MTL.Device) -> (vertex_buffer, index_buffer, instance_buffer: ^MTL.Buffer) {
	s :: 0.5
	positions := []Vertex_Data{
		// Positions      Normals
		{{-s, -s, +s}, {0,  0,  1}},
		{{+s, -s, +s}, {0,  0,  1}},
		{{+s, +s, +s}, {0,  0,  1}},
		{{-s, +s, +s}, {0,  0,  1}},
		{{+s, -s, +s}, {1,  0,  0}},
		{{+s, -s, -s}, {1,  0,  0}},
		{{+s, +s, -s}, {1,  0,  0}},
		{{+s, +s, +s}, {1,  0,  0}},
		{{+s, -s, -s}, {0,  0, -1}},
		{{-s, -s, -s}, {0,  0, -1}},
		{{-s, +s, -s}, {0,  0, -1}},
		{{+s, +s, -s}, {0,  0, -1}},

		{{-s, -s, -s}, {-1, 0,  0}},
		{{-s, -s, +s}, {-1, 0,  0}},
		{{-s, +s, +s}, {-1, 0,  0}},
		{{-s, +s, -s}, {-1, 0,  0}},

		{{-s, +s, +s}, {0,  1,  0}},
		{{+s, +s, +s}, {0,  1,  0}},
		{{+s, +s, -s}, {0,  1,  0}},
		{{-s, +s, -s}, {0,  1,  0}},

		{{-s, -s, -s}, {0, -1,  0}},
		{{+s, -s, -s}, {0, -1,  0}},
		{{+s, -s, +s}, {0, -1,  0}},
		{{-s, -s, +s}, {0, -1,  0}},
	}
	indices := []u16{
		 0,  1,  2,  2,  3,  0, // front
		 4,  5,  6,  6,  7,  4, // right
		 8,  9, 10, 10, 11,  8, // back
		12, 13, 14, 14, 15, 12, // left
		16, 17, 18, 18, 19, 16, // top
		20, 21, 22, 22, 23, 20, // bottom
	}

	vertex_buffer   = device->newBufferWithSlice(positions[:], {.StorageModeManaged})
	index_buffer    = device->newBufferWithSlice(indices[:],   {.StorageModeManaged})
	instance_buffer = device->newBuffer(NUM_INSTANCES*size_of(Instance_Data), {.StorageModeManaged})
	return
}

metal_main :: proc() -> (err: ^NS.Error) {
	SDL.SetHint(SDL.HINT_RENDER_DRIVER, "metal")
	SDL.setenv("METAL_DEVICE_WRAPPER_TYPE", "1", 0)
	SDL.Init({.VIDEO})
	defer SDL.Quit()

	window := SDL.CreateWindow("Metal in Odin - 06 lighting",
		SDL.WINDOWPOS_CENTERED, SDL.WINDOWPOS_CENTERED,
		1024, 1024,
		{.ALLOW_HIGHDPI, .HIDDEN, .RESIZABLE},
	)
	defer SDL.DestroyWindow(window)

	window_system_info: SDL.SysWMinfo
	SDL.GetVersion(&window_system_info.version)
	SDL.GetWindowWMInfo(window, &window_system_info)
	assert(window_system_info.subsystem == .COCOA)

	native_window := (^NS.Window)(window_system_info.info.cocoa.window)

	device := MTL.CreateSystemDefaultDevice()
	defer device->release()

	fmt.println(device->name()->odinString())

	swapchain := CA.MetalLayer.layer()
	defer swapchain->release()

	swapchain->setDevice(device)
	swapchain->setPixelFormat(.BGRA8Unorm_sRGB)
	swapchain->setFramebufferOnly(true)
	swapchain->setFrame(native_window->frame())

	native_window->contentView()->setLayer(swapchain)
	native_window->setOpaque(true)
	native_window->setBackgroundColor(nil)

	library, pso := build_shaders(device) or_return
	defer library->release()
	defer pso->release()

	// Build Depth Stencil State
	depth_stencil_state: ^MTL.DepthStencilState
	depth_desc := MTL.DepthStencilDescriptor.alloc()->init()
	depth_desc->setDepthCompareFunction(.Less)
	depth_desc->setDepthWriteEnabled(true)
	depth_stencil_state = device->newDepthStencilState(depth_desc)
	depth_desc->release()

	vertex_buffer, index_buffer, instance_buffer := build_buffers(device)
	defer vertex_buffer->release()
	defer index_buffer->releas