package gfx;

import GL "vendor:OpenGL"

SSBO :: struct { id: u32 }

create_ssbo :: proc {
    create_ssbo_vector,
    create_ssbo_array,
    create_ssbo_ptr,
}

@export
create_ssbo_vector :: proc(data: [dynamic]$T) -> (ssbo: SSBO) {
    
    GL.GenBuffers(1, &ssbo.id)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo.id)
    GL.BufferData(GL.SHADER_STORAGE_BUFFER, size_of(T) * len(data), &data[0], GL.DYNAMIC_DRAW)

    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, 0)

    return ssbo
}

@export
create_ssbo_array :: proc(data: []$T) -> (ssbo: SSBO) {
    
    GL.GenBuffers(1, &ssbo.id)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo.id)
    GL.BufferData(GL.SHADER_STORAGE_BUFFER, int(size), &data, size_of(T) * len(data), GL.DYNAMIC_DRAW)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, 0)

    return ssbo
}

@export
create_ssbo_ptr :: proc(data: ^$T, size: int) -> (ssbo: SSBO) {
    
    GL.GenBuffers(1, &ssbo.id)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo.id)
    GL.BufferData(GL.SHADER_STORAGE_BUFFER, size, data, GL.DYNAMIC_DRAW)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, 0)

    return ssbo
}

@export
bind_ssbo_base :: #force_inline proc (using ssbo: SSBO, binding: u32) {
	GL.BindBufferBase(GL.SHADER_STORAGE_BUFFER, binding, id)
}

@export
bind_ssbo :: #force_inline proc (using ssbo: SSBO, binding: u32) {
	GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, id)
}

@export
unbind_ssbo :: #force_inline proc() {
	GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, 0)
}

@export
delete_ssbo :: proc (ssbo: SSBO) {
	ptr := [1]u32{ssbo.id}
	GL.DeleteBuffers(1, &ptr[0])
}
