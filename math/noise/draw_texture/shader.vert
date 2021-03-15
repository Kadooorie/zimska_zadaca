#version 330 core

layout(location = 0) in vec2 xy;
layout(location = 1) in vec2 passed_texture_coords;
		
uniform mat4 u_projection;
out vec2 texture_coords;

void main() {
        // Get rid of the z dimension.
    