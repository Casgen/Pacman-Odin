package gfx

import "core:math/linalg"
import stb_image "vendor:stb/image"
import "core:c/libc"
import GL "vendor:OpenGL"

SpriteSheet :: struct {
    width, height: i32,
    texture_id: u32,
}

load_spritesheet :: proc(path: cstring) -> SpriteSheet {
    
    stb_image.set_flip_vertically_on_load_thread(true)

    spritesheet: SpriteSheet


    desired_channels: libc.int = 4

    contents := stb_image.load(path, &spritesheet.width, &spritesheet.height,&desired_channels, 4)

    GL.GenTextures(1, &spritesheet.texture_id) 
    GL.BindTexture(GL.TEXTURE_2D, spritesheet.texture_id) 

    GL.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR)
    GL.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR)

    GL.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE)
    GL.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE)

    GL.TexImage2D(GL.TEXTURE_2D, 0,GL.RGBA32F, spritesheet.width, spritesheet.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, nil)

    return spritesheet

}

bind_spritesheet :: proc(using spritesheet: ^SpriteSheet, slot: u32) {
    GL.ActiveTexture(GL.TEXTURE0 + slot)
    GL.BindTexture(GL.TEXTURE_2D, texture_id)
}


