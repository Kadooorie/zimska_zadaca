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
	texcoord: glm.vec2,
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

TEXTURE_WIDTH  :: 128
TEXTURE_HEIGHT :: 128

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
		float2 texcoord;
	};

	struct Vertex_Data {
		packed_float3 position;
		packed_float3 normal;
		packed_float2 texcoord;
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

		o.texcoord = float2(vd.texcoord.xy);

		o.color = half3(id.color.rgb);
		return o;
	}

	half4 fragment fragment_main(v2f in                              [[stage_in]],
	                             texture2d<half, access::sample> tex [[texture(0)]]) {
		constexpr sampler s(address::repeat, filter::linear);
		half3 texel = tex.sample(s, in.texcoord).rgb;

		// assume light coming from front-top-right
		float3 l = normalize(float3(1.0, 1.0, 0.8));
		float3 n = normalize(in.normal);

		float ndotl = saturate(dot(n, l));

		half3 illum = in.color * texel * 0.1 + in.color * texel * ndotl;
		return half4(illum, 1.0);
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

build_buffers :: proc(device: ^MTL.Device) -> (vertex_buffer, index_buffer, instance_buffer, texture_animation_buffer: ^MTL.Buffer) {
	s :: 0.5
	positions := []Vertex_Data{
		//                                         Texture
		//   Positions           Normals         Coordinates
		{{-s, -s, +s}, { 0,  0,  1}, {0, 1}},
		{{+s, -s, +s}, { 0,  0,  1}, {1, 1}},
		{{+s, +s, +s}, { 0,  0,  1}, {1, 0}},
		{{-s, +s, +s}, { 0,  0,  1}, {0, 0}},

		{{+s, -s, +s}, { 1,  0,  0}, {0, 1}},
		{{+s, -s, -s}, { 1,  0,  0}, {1, 1}},
		{{+s, +s, -s}, { 1,  0,  0}, {1, 0}},
		{{+s, +s, +s}, { 1,  0,  0}, {0, 0}},

		{{+s, -s, -s}, { 0,  0, -1}, {0, 1}},
		{{-s, -s, -s}, { 0,  0, -1}, {1, 1}},
		{{-s, +s, -s}, { 0,  0, -1}, {1, 0}},
		{{+s, +s, -s}, { 0,  0, -1}, {0, 0}},

		{{-s, -s, -s}, {-1,  0,  0}, {0, 1}},
		{{-s, -s, +s}, {-1,  0,  0}, {1, 1}},
		{{-s, +s, +s}, {-1,  0,  0}, {1, 0}},
		{{-s, +s, -s}, {-1,  0,  0}, {0, 0}},

		{{-s, +s, +s}, { 0,  1,  0}, {0, 1}},
		{{+s, +s, +s}, { 0,  1,  0}, {1, 1}},
		{{+s, +s, -s}, { 0,  1,  0}, {1, 0}},
		{{-s, +s, -s}, { 0,  1,  0}, {0, 0}},

		{{-s, -s, -s}, { 0, -1,  0}, {0, 1}},
		{{+s, -s, -s}, { 0, -1,  0}, {1, 1}},
		{{+s, -s, +s}, { 0, -1,  0}, {1, 0}},
		{{-s, -s, +s}, { 0, -1,  0}, {0, 0}},
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
	texture_animation_buffer = device->newBuffer(size_of(u32), {.StorageModeManaged})
	return
}

build_texture :: proc(device: ^MTL.Device) -> ^MTL.Texture {
	desc := MTL.TextureDescriptor.alloc()->init()
	defer desc->release()

	desc->setWidth(TEXTURE_WIDTH)
	desc->setHeight(TEXTURE_HEIGHT)
	desc->setPixelFormat(.RGBA8Unorm)
	desc->setStorageMode(.Managed)
	desc->setUsage({.ShaderRead, .ShaderWrite})

	return device->newTextureWithDescriptor(desc)
}

build_compute_pipeline :: proc(device: ^MTL.Device) -> (pso: ^MTL.ComputePipelineState, err: ^NS.Error) {
	kernel_src := `
	#include <metal_stdlib>
	using namespace metal;

	kernel void mandelbrot_set(texture2d<half, access::write> tex [[texture(0)]],
	                           uint2 index                        [[thread_position_in_grid]],
	                           uint2 grid_size                    [[threads_per_grid]],
	                           device const uint* frame           [[buffer(0)]]) {
		constexpr float ANIMATION_FREQUENCY = 0.01;
		constexpr float ANIMATION_SPEED = 4;
		constexpr float ANIMATION_SCALE_LOW = 0.62;
		constexpr float ANIMATION_SCALE = 0.38;

		constexpr float2 MANDELBROT_PIXEL_OFFSET = {-0.2, -0.35};
		constexpr float2 MANDELBROT_ORIGIN = {-1.2, -0.32};
		constexpr float2 MANDELBROT_SCALE = {2.2, 2.0};

		// Map time to zoom value in [ANIMATION_SCALE_LOW, 1]
		flo