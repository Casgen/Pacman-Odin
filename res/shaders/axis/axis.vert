#version 450

layout (location = 0) in vec2 a_position;
layout (location = 1) in vec3 a_color;

layout (location = 0) out vec3 o_color;

void main() {
	gl_Position = vec4(a_position, 0.f, 1.f);
	o_color = a_color;
}
