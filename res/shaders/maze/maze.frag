#version 450

layout (location = 0) in vec2 i_tex_coords;

layout (location = 0) out vec4 o_frag_color;

uniform sampler2D u_maze_tex;

void main() {
	o_frag_color = texture(u_maze_tex, i_tex_coords);
}
