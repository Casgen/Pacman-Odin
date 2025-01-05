package gfx

import GL "vendor:OpenGL"

VaoId :: u32
VboId :: u32

Buffer :: struct {
    id: VboId,
    target: u32
}

create_vao :: proc() -> u32 {
    id: u32
    GL.GenVertexArrays(1, &id)

    return id
}

delete_vao :: proc(id: VaoId) {
	id_ptr := []u32{id}
	GL.DeleteVertexArrays(1, &id_ptr[0])
}

create_vertex_buffer :: proc {
	create_vertex_buffer_multiptr,
	create_vertex_buffer_slice,
}

create_vertex_buffer_multiptr :: proc(data: [^]$T, size: int, usage: u32 = GL.STATIC_DRAW) -> Buffer {
	assert(data != nil)

    buffer: Buffer
    buffer.target = GL.ARRAY_BUFFER
    
    GL.GenBuffers(1, &buffer.id) 
    GL.BindBuffer(GL.ARRAY_BUFFER, buffer.id)
    GL.BufferData(GL.ARRAY_BUFFER, size, data, usage)
    GL.BindBuffer(GL.ARRAY_BUFFER, 0)

    return buffer
}

create_vertex_buffer_slice :: proc(data: []$T, usage: u32 = GL.STATIC_DRAW) -> Buffer {
	assert(data != nil)

    buffer: Buffer
    buffer.target = GL.ARRAY_BUFFER
    
    GL.GenBuffers(1, &buffer.id) 
    GL.BindBuffer(GL.ARRAY_BUFFER, buffer.id)
    GL.BufferData(GL.ARRAY_BUFFER, size_of(T) * len(data), &data[0], usage)
    GL.BindBuffer(GL.ARRAY_BUFFER, 0)

    return buffer
}

create_index_buffer :: proc(data: [^]u32, size: int, usage: u32 = GL.STATIC_DRAW) -> Buffer {

    buffer: Buffer
    buffer.target = GL.ELEMENT_ARRAY_BUFFER
    
    GL.GenBuffers(1, &buffer.id) 
    GL.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, buffer.id)
    GL.BufferData(GL.ELEMENT_ARRAY_BUFFER, size, data, usage)
    GL.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, 0)

    return buffer
}

delete_buffer :: proc(using buffer: ^Buffer) {
    GL.DeleteBuffers(1, &buffer.id)
}

bind_buffer :: proc(using buffer: ^Buffer) {
    GL.BindBuffer(target, id)
}

unbind_buffer :: proc(using buffer: ^Buffer) {
    GL.BindBuffer(target, 0)
}

bind_vao :: #force_inline proc(id: VaoId) {
	GL.BindVertexArray(id)
}

unbind_vao :: #force_inline proc() {
	GL.BindVertexArray(0)
}

bind_buffer_base :: #force_inline proc(ssbo: SSBO, target: u32) {
    GL.BindBufferBase(GL.SHADER_STORAGE_BUFFER, target, ssbo.id)
}
