package gfx

import GL "vendor:OpenGL"

Buffer :: struct {
    id: u32,
    target: u32
}

@export
create_vao :: proc() -> u32 {
    id: u32
    GL.GenVertexArrays(1, &id)

    return id
}

@export
create_vertex_buffer :: proc(data: [^]$T, size: int, usage: u32 = GL.STATIC_DRAW) -> Buffer {

    buffer: Buffer
    buffer.target = GL.ARRAY_BUFFER
    
    GL.GenBuffers(1, &buffer.id) 
    GL.BindBuffer(GL.ARRAY_BUFFER, buffer.id)
    GL.BufferData(GL.ARRAY_BUFFER, size, data, usage)
    GL.BindBuffer(GL.ARRAY_BUFFER, 0)

    return buffer
}

@export
create_index_buffer :: proc(data: [^]u32, size: int, usage: u32 = GL.STATIC_DRAW) -> Buffer {

    buffer: Buffer
    buffer.target = GL.ELEMENT_ARRAY_BUFFER
    
    GL.GenBuffers(1, &buffer.id) 
    GL.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, buffer.id)
    GL.BufferData(GL.ELEMENT_ARRAY_BUFFER, size, data, usage)
    GL.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, 0)

    return buffer
}

@export
delete_buffer :: proc(using buffer: ^Buffer) {
    GL.DeleteBuffers(1, &id)
}

@export
bind_buffer :: proc(using buffer: ^Buffer) {
    GL.BindBuffer(target, id)
}

@export
unbind_buffer :: proc(using buffer: ^Buffer) {
    GL.BindBuffer(target, 0)
}

