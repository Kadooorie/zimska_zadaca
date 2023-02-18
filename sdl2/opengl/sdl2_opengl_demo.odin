
package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"

import SDL "vendor:sdl2"
import gl "vendor:OpenGL"

GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

main :: proc() {
	WINDOW_WIDTH  :: 854
	WINDOW_HEIGHT :: 480

	SDL.Init({.VIDEO})
	defer SDL.Quit()

	window := SDL.CreateWindow("Odin SDL2 Demo", SDL.WINDOWPOS_UNDEFINED, SDL.WINDOWPOS_UNDEFINED, WINDOW_WIDTH, WINDOW_HEIGHT, {.OPENGL})
	if window == nil {
		fmt.eprintln("Failed to create window")
		return
	}
	defer SDL.DestroyWindow(window)

	SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK,  i32(SDL.GLprofile.CORE))
	SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
	SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

	gl_context := SDL.GL_CreateContext(window)
	defer SDL.GL_DeleteContext(gl_context)

	// load the OpenGL procedures once an OpenGL context has been established
	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, SDL.gl_set_proc_address)

	// useful utility procedures that are part of vendor:OpenGl
	program, program_ok := gl.load_shaders_source(vertex_source, fragment_source)
	if !program_ok {
		fmt.eprintln("Failed to create GLSL program")
		return
	}
	defer gl.DeleteProgram(program)

	gl.UseProgram(program)

	uniforms := gl.get_uniforms_from_program(program)
	defer delete(uniforms)

	vao: u32
	gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	// initialization of OpenGL buffers
	vbo, ebo: u32
	gl.GenBuffers(1, &vbo); defer gl.DeleteBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo); defer gl.DeleteBuffers(1, &ebo)

	// struct declaration
	Vertex :: struct {
		pos: glm.vec3,
		col: glm.vec4,
	}

	vertices := []Vertex{
		{{-0.5, +0.5, 0}, {1.0, 0.0, 0.0, 0.75}},
		{{-0.5, -0.5, 0}, {1.0, 1.0, 0.0, 0.75}},
		{{+0.5, -0.5, 0}, {0.0, 1.0, 0.0, 0.75}},
		{{+0.5, +0.5, 0}, {0.0, 0.0, 1.0, 0.75}},
	}

	indices := []u16{
		0, 1, 2,
		2, 3, 0,
	}

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(vertices)*size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, col))

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices)*size_of(indices[0]), raw_data(indices), gl.STATIC_DRAW)

	// high precision timer
	start_tick := time.tick_now()

	loop: for {
		duration := time.tick_since(start_tick)
		t := f32(time.duration_seconds(duration))

		// event polling
		event: SDL.Event
		for SDL.PollEvent(&event) {
			// #partial switch tells the compiler not to error if every case is not present
			#partial switch event.type {
			case .KEYDOWN:
				#partial switch event.key.keysym.sym {
				case .ESCAPE:
					// labelled control flow
					break loop
				}
			case .QUIT:
				// labelled control flow
				break loop