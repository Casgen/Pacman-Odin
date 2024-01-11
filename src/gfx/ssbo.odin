package gfx;

import GL "vendor:OpenGL"

SSBO :: struct {
    id, binding: u32
}

create_ssbo :: proc {
    create_ssbo_vector,
    create_ssbo_array,
    create_ssbo_ptr,
}

create_ssbo_vector :: proc(data: [dynamic]$T, binding: u32) -> (ssbo: SSBO) {
    
    ssbo.binding = binding
    GL.GenBuffers(1, &ssbo.id)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo.id)
    GL.BufferData(GL.SHADER_STORAGE_BUFFER, size_of(T) * len(data), data[0], GL.DYNAMIC_DRAW)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, 0)

    return ssbo
}

create_ssbo_array :: proc(data: []$T, binding: u32) -> (ssbo: SSBO) {
    
    ssbo.binding = binding
    GL.GenBuffers(1, &ssbo.id)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo.id)
    GL.BufferData(GL.SHADER_STORAGE_BUFFER, int(size), &data, size_of(T) * len(data), GL.DYNAMIC_DRAW)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, 0)

    return ssbo
}

create_ssbo_ptr :: proc(data: ^$T, size: int, binding: u32) -> (ssbo: SSBO) {
    
    ssbo.binding = binding
    GL.GenBuffers(1, &ssbo.id)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo.id)
    GL.BufferData(GL.SHADER_STORAGE_BUFFER, size, data, GL.DYNAMIC_DRAW)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, 0)

    return ssbo
}

