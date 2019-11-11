
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

build_shaders :: proc(device: ^MTL.Device) -> (library: ^MTL.Library, pso: ^MTL.RenderPipelineState, err: ^NS.Error) {
	shader_src := `
	#include <metal_stdlib>
	using namespace metal;

	struct v2f {
		float4 position [[position]];
		half3 color;
	};

	struct Vertex_Data {
		packed_float3 position;
	};

	struct Instance_Data {
		float4x4 transform;
		float4   color;
	};

	v2f vertex vertex_main(device const Vertex_Data*   vertex_data   [[buffer(0)]],
	                       device const Instance_Data* instance_data [[buffer(1)]],
	                       uint vertex_id                            [[vertex_id]],
	                       uint instance_id                          [[instance_id]]) {
		v2f o;
		float4 pos = float4(vertex_data[vertex_id].position, 1.0);
		o.position = instance_data[instance_id].transform * pos;
		o.color = half3(instance_data[instance_id].color.rgb);
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