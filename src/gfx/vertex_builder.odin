package gfx

import GL "vendor:OpenGL"
import "base:runtime"

VertexAttribute :: struct {
    count:      u32,         
    value_type: GlValueType, 
    normalized: bool,
}

VertexBuilder :: struct {
    attributes: [dynamic]VertexAttribute,
    stride:     u32,
}

GlValueType :: enum {
    Float,
    UByte,
    Byte,
    UInt,
    Int,
    Bool
}

GlValue_Vectors :: [GlValueType][2]u32 {
    .Float  = {GL.FLOAT, 4},
    .UByte  = {GL.UNSIGNED_BYTE, 1},
    .Byte   = {GL.BYTE, 1},
    .UInt   = {GL.UNSIGNED_INT, 4},
    .Int    = {GL.INT, 4},
    .Bool   = {GL.BOOL, 4},
}

gl_value_vectors := GlValue_Vectors

push_attribute :: proc {
    push_attribute_struct,
    push_attribute_params,
}


@export
push_attribute_struct :: proc(using builder: ^VertexBuilder, attribute: VertexAttribute) {
    append(&attributes, attribute)
    stride += attribute.count * gl_value_vectors[attribute.value_type][1]
}

@export
push_attribute_params :: proc(using builder: ^VertexBuilder, count: u32, value_type: GlValueType, normalized: bool = false) {
    append(&attributes, VertexAttribute{count, value_type, normalized})
    stride += count * gl_value_vectors[value_type][1]
}


@export
generate_layout :: proc(using builder: ^VertexBuilder, vbo_id: u32, vao_id: u32) {

    GL.BindVertexArray(vao_id) 
    GL.BindBuffer(GL.ARRAY_BUFFER, vbo_id)

    offset: uintptr = 0;

    for &attr, i in attributes {
        
        GL.EnableVertexAttribArray(u32(i))

        type := gl_value_vectors[attr.value_type]

        GL.VertexAttribPointer(u32(i), i32(attr.count), type[0], false, i32(builder.stride), offset)

        offset += uintptr(attr.count * type[1])
    }

    GL.BindVertexArray(0)
    GL.BindBuffer(GL.ARRAY_BUFFER, 0)

}



