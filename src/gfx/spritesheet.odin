package gfx

import "core:math/linalg"
import "core:c/libc"
import GL "vendor:OpenGL"


SpriteSheet :: struct {
	tex: Texture2D,
}

SPRITESHEET_BLOCK_SIZE : i32 : 16

@(private)
spritesheet: ^SpriteSheet = nil;

load_spritesheet :: proc(path: cstring) {
	// Have to call `new` here. It is a pointer after all!
	spritesheet = new(SpriteSheet)
	spritesheet.tex = create_texture_2d(path)
}

get_spritesheet :: proc() -> ^SpriteSheet {
	assert(spritesheet != nil, "Couldn't obtain the spritesheet! The spritesheet was not loaded!");

	return spritesheet;
}

bind_spritesheet_as_image :: proc(binding: u32) {
    GL.BindImageTexture(binding, spritesheet.tex.id, 0, GL.FALSE, 0, GL.READ_WRITE, GL.RGBA32F);
}

bind_spritesheet :: proc(slot: u32) {
    GL.ActiveTexture(GL.TEXTURE0 + slot)
    GL.BindTexture(GL.TEXTURE_2D, spritesheet.tex.id)
}

destroy_spreadsheet :: proc() {
	ptr: [1]u32 = [1]u32{spritesheet.tex.id}
	GL.DeleteTextures(1, &ptr[0])
}
