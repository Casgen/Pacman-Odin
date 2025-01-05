#version 450

layout (location = 0) in vec2 a_Position;
layout (location = 1) in vec4 a_Color;
layout (location = 2) in float a_PointSize;

layout (location = 0) out vec4 o_Color;
layout (location = 1) out float o_PointSize;
layout (location = 2) out flat int o_Id;

void main() {
    o_Color = a_Color;
    o_Id = gl_VertexID;
    gl_PointSize = o_PointSize = a_PointSize;
    gl_Position = vec4(a_Position.x, a_Position.y, 0.0, 1.0);
}
