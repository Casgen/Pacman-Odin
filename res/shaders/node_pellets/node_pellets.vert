#version 450

layout (location = 0) in vec2 a_Position;
layout (location = 1) in vec4 a_Color;

layout (location = 0) out vec4 v_Color;

void main() {
    v_Color = a_Color;
    gl_PointSize = 5;
    gl_Position = vec4(a_Position.x, a_Position.y, 0.0, 1.0);
}
