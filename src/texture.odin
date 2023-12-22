package main

import STB "vendor:stb/image"

Spritesheet :: struct {
    width, height: u32,
    block_size: u16,
    channels: u8,
    data: [^]u8
}


load_spritesheet :: proc(block_size: u16) -> Spritesheet {

    spritesheet: Spritesheet

    x, y, channels_in_file: i32 = 0, 0, 0

    spritesheet.data = STB.load("res/spritesheet.png", &x, &y, &channels_in_file, 3)

    return spritesheet
}
