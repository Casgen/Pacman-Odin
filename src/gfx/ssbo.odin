package gfx;

import GL "vendor:OpenGL"

SSBO :: struct { id: u32 }

create_ssbo :: proc {
    create_ssbo_vector,
    create_ssbo_array,
    create_ssbo_ptr,
}

create_ssbo_vector :: proc(data: [dynamic]$T) -> (ssbo: SSBO) {
    
    GL.GenBuffers(1, &ssbo.id)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo.id)
    GL.BufferData(GL.SHADER_STORAGE_BUFFER, size_of(T) * len(data), &data[0], GL.DYNAMIC_DRAW)

    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, 0)

    return ssbo
}

create_ssbo_array :: proc(data: []$T) -> (ssbo: SSBO) {
    
    GL.GenBuffers(1, &ssbo.id)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo.id)
    GL.BufferData(GL.SHADER_STORAGE_BUFFER, int(size), &data, size_of(T) * len(data), GL.DYNAMIC_DRAW)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, 0)

    return ssbo
}

create_ssbo_ptr :: proc(data: ^$T, size: int) -> (ssbo: SSBO) {
    
    GL.GenBuffers(1, &ssbo.id)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo.id)
    GL.BufferData(GL.SHADER_STORAGE_BUFFER, size, data, GL.DYNAMIC_DRAW)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, 0)

    return ssbo
}

bind_ssbo_base :: proc (using ssbo: SSBO, binding: u32) {
	GL.BindBufferBase(GL.SHADER_STORAGE_BUFFER, binding, id)
}

bind_ssbo :: proc (using ssbo: SSBO, binding: u32) {
	GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, id)
}
