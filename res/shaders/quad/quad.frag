#version 450

layout (location = 0) in vec4 i_Color;
layout (location = 1) in vec2 i_texCoords;

layout (location = 0) out vec4 o_Color;


void main() {
    o_Color = i_Color;
}
