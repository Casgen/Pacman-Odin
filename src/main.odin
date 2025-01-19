package main

import GL "vendor:OpenGL"
import SDL "vendor:sdl2"
import "core:time"
import "core:c/libc"
import "game"

GameState :: struct {
	perf_frequency: f64,
	renderer:       ^SDL.Renderer,
	window:         ^SDL.Window,
	gl_context:     SDL.GLContext,
}

app := GameState{
	renderer = nil,
	window = nil,
	gl_context = nil
}

main :: proc() {

	game_memory, ok := game.init()

	if !ok {
		panic("Failed to run the game!")
	}

	time_start, time_last: f64
	timestep: f32 = 0

	event: SDL.Event
	state: [^]u8

    delta_time: f32

	for (game_memory.game_state.is_running) {
		game.update(&game_memory, &delta_time)
	}

	game.deinit(&game_memory)
}

