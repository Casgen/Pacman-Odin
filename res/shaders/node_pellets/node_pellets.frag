#version 450

layout (location = 0) in vec4 v_Color;

layout (location = 0) out vec4 o_Color;

void main() {

    vec2 centerPointCoord = gl_PointCoord * 2 - 1;

    float distance = centerPointCoord.x * centerPointCoord.x + centerPointCoord.y * centerPointCoord.y;

    if (distance > 0.25) {
        o_Color = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }


    o_Color = v_Color;
}
