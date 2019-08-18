
package main

import NS "vendor:darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA "vendor:darwin/QuartzCore"

import SDL "vendor:sdl2"

import "core:fmt"
import "core:os"

build_shaders :: proc(device: ^MTL.Device) -> (library: ^MTL.Library, pso: ^MTL.RenderPipelineState, err: ^NS.Error) {
	shader_src := `
	#include <metal_stdlib>
	using namespace metal;

	struct v2f {
		float4 position [[position]];
		half3 color;
	};

	v2f vertex vertex_main(uint vertex_id                        [[vertex_id]],
	                       device const packed_float3* positions [[buffer(0)]],
	                       device const packed_float3* colors    [[buffer(1)]]) {
		v2f o;
		o.position = float4(positions[vertex_id], 1.0);
		o.color = half3(colors[vertex_id]);
		return o;
	}

	half4 fragment fragment_main(v2f in [[stage_in]]) {
		return half4(in.color, 1.0);
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

	pso = device->newRenderPipelineStateWithDescriptor(desc) or_return
	return
}

build_buffers :: proc(device: ^MTL.Device) -> (vertex_positions_buffer, vertex_colors_buffer: ^MTL.Buffer) {