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

	half4 fragment fragment