#version 450

layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec2 a_texCoords;
layout (location = 2) in vec4 a_Color;

layout (location = 0) out vec4 o_Color;
layout (location = 1) out vec2 o_texCoords;

layout (std140, binding = 0) uniform CameraMatrices {
	mat4 proj;
	mat4 view;
} mats;

uniform vec2 u_Scale;
uniform vec2 u_Position;

void main() {
    o_texCoords = a_texCoords;

    vec2 new_position = a_Position.xy * u_Scale;
    new_position += u_Position;

    o_Color = a_Color;
    gl_Position = mats.proj * mats.view * vec4(new_position, 0.0, 1.0);
}
