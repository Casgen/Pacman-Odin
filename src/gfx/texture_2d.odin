package gfx

import stbi "vendor:stb/image"
import "core:c/libc"
import GL "vendor:OpenGL"
import "core:path/filepath"
import "core:strings"

Texture2D :: struct {
	id: u32,
	width, height: i32,
}

// By default, loads and creates an image with the RGBA colors.
// Don't forget to bind the texture afterwards!
// 
// TODO: Implement further options for interpreting more formats!
@export
create_texture_2d_path :: proc(path: cstring) -> Texture2D {

    stbi.set_flip_vertically_on_load_thread(false)

    img_width: i32
    img_height: i32

	img_id: u32

    desired_channels: libc.int = 4

    contents := stbi.load(path, &img_width, &img_height, &desired_channels, 4)
	defer stbi.image_free(contents)

	if contents == nil {
		panic("Failed to load the spritesheet! quiting the game!")
	}

    GL.GenTextures(1, &img_id) 
    GL.BindTexture(GL.TEXTURE_2D, img_id) 

    GL.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR)
    GL.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR)

    GL.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE)
    GL.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE)

    GL.TexImage2D(GL.TEXTURE_2D, 0, GL.RGBA32F, img_width, img_height, 0, GL.RGBA, GL.UNSIGNED_BYTE, contents)

    return {img_id, img_width, img_height}
}

// Creates a blank 2D texture
// TODO: Implement further options for interpreting more formats!
@export
create_texture_2d_empty :: proc(width: i32, height: i32) -> Texture2D {
	img_id: u32

    GL.GenTextures(1, &img_id) 
    GL.BindTexture(GL.TEXTURE_2D, img_id) 

    GL.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR)
    GL.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR)

    GL.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE)
    GL.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE)

    GL.TexImage2D(GL.TEXTURE_2D, 0, GL.RGBA32F, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, nil)

    return {img_id, width, height}
}

create_texture_2d :: proc {
	create_texture_2d_path,
	create_texture_2d_empty,
}

@export
bind_texture_2d :: proc(using texture: Texture2D, slot: u32) {
    GL.ActiveTexture(GL.TEXTURE0 + slot)
    GL.BindTexture(GL.TEXTURE_2D, id)
}

// Binds the texture as an 'image2D' type. Used for example for compute shaders.
// The binding point number should match to one of the images you want in the shaders.
// for ex. `layout (rgba32f, binding = 1) uniform image2D spritesheet;`, the `binding` here
// should be 1.
@export
bind_texture_as_image :: proc(using texture: Texture2D, binding: u32) {
    GL.BindImageTexture(binding, id, 0, GL.FALSE, 0, GL.READ_WRITE, GL.RGBA32F);
}

@export
unbind_texture_2d :: proc() {
	GL.BindTexture(GL.TEXTURE_2D, 0)
}

@export
destroy_texture_2d :: proc(using tex: ^Texture2D) {
	ptr: [1]u32 = [1]u32{tex.id}
	GL.DeleteTextures(1, &ptr[0])

	tex.id = 0
	tex.width = 0
	tex.height = 0
}

