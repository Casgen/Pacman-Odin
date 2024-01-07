#version 450

layout (location = 0) in vec2 a_Position;
layout (location = 1) in vec4 a_Color;
layout (location = 2) in float a_PointSize;

layout (location = 0) out vec4 v_Color;
layout (location = 1) out vec4 v_PointSize;

void main() {
    v_Color = a_Color;
    gl_PointSize = a_PointSize;
    gl_Position = vec4(a_Position.x, a_Position.y, 0.0, 1.0);
}
