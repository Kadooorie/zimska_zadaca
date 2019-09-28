package main

import NS "vendor:darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA "vendor:darwin/QuartzCore"

import SDL "vendor:sdl2"

import "core:fmt"
import "core:os"


Frame_Data :: struct {
	angle: f32,
}

build_shaders :: proc(device: ^MTL.Device) -> (library: ^MTL.Library, pso: ^MTL.RenderPipelineState, err: ^NS.Error) {
	shader_src := `
	#include <metal_stdlib>
	using namespace metal;

	struct v2f {
		float4 position [[position]];
		half3 color;
	};

	struct Vertex_Data {
		device packed_float3* positions [[id(0)]];
		device packed_float3* colors    [[id(1)]];
	};

	struct Frame_Data {
		float angle;
	};

	v2f vertex vertex_main(device const Vertex_Data* vertex_data [[buffer(0)]],
	                       device const Frame_Data*  frame_data  [[buffer(1)]],
	                       uint vertex_id                        [[vertex_id]]) {
		float a = frame_data->angle;
		float3x3 rotation_matrix = float3x3(sin(a), cos(a), 0.0, cos(a), -sin(a), 0.0, 0.0, 0.0, 1.0);
		float3 position = float3(vertex_data->positions[vertex_id]);
		v2f o;
		o.position = float4(rotation_matrix * position, 1.0);
		o.color = half3(vertex_data->colors[vertex_id]);
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

build_buffers :: proc(device: ^MTL.Device, library: ^MTL.Library) -> (vertex_positions_buffer, vertex_colors_buffer, arg_buffer: ^MTL.Buffer) {
	NUM_VERTICES :: 3
	positions := [NUM_VERTICES][3]f32{
		{-0.8,  0.8, 0.0},
		{ 0.0, -0.8, 0.0},
		{+0.8,  0.8, 0.0},
	}
	colors := [NUM_VERTICES][3]f32{
		{1.0, 0.3, 0.2},
		{0.8, 1.0, 0.0},
		{0.8, 0.0, 1.0},
	}

	vertex_positions_buffer = device->newBufferWithSlice(positions[:], {.StorageModeManaged})
	vertex_colors_buffer    = device->newBufferWithSlice(colors[:],    {.StorageModeManaged})

	vertex_function := library->newFunctionWithName(NS.AT("vertex_main"))
	defer vertex_function->release()

	arg_encoder := vertex_function->newArgumentEncoder(0)
	defer arg_encoder->release()

	arg_buffer = device->newBuffer(arg_encoder->encodedLength(), {.StorageModeManaged})
	arg_encoder->setArgumentBufferWithOffset(arg_buffer, 0)
	arg_encoder->setBuffer(vertex_positions_buffer, 0, 0)
	arg_encoder->setBuffer(vertex_colors_buffer,    0, 1)
	arg_buffer->didModifyRange(NS.Range_Make(0, arg_