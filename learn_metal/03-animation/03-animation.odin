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

	struct Vertex_