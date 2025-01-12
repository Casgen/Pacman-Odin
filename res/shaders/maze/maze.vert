#version 450

layout (location = 0) in vec3 a_position;
layout (location = 1) in vec2 a_tex_coords;
layout (location = 2) in vec4 a_color;

layout (location = 0) out vec2 o_tex_coords;

layout (std140, binding = 0) uniform CameraMatrices {
	mat4 proj;
	mat4 view;
} mats;

void main() {
	o_tex_coords = a_tex_coords;
	gl_Position = mats.proj * mats.view * vec4(a_position, 1.f);
}
