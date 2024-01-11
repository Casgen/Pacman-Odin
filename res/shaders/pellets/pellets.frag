#version 450

layout (location = 0) in vec4 i_Color;
layout (location = 1) in float i_PointSize;
layout (location = 2) in flat int i_Id;

layout (location = 0) out vec4 o_Color;

layout(std430, binding = 0) buffer pellet_visiblity
{
    uint visibility[];
};

void main() {

    if (!bool(visibility[i_Id])) {
        o_Color = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }

    vec2 centerPointCoord = gl_PointCoord * 2 - 1;

    float distance = centerPointCoord.x * centerPointCoord.x + centerPointCoord.y * centerPointCoord.y;

    if (distance > i_PointSize/80) {
        o_Color = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }

    o_Color = i_Color;
}
