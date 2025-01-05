package main

import Consts "constants"
import "core:fmt"
import GL "vendor:OpenGL"
import SDL "vendor:sdl2"
import "core:time"
import "core:mem"
import "core:c/libc"
import "core:dynlib"
import "gfx"
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

debug_callback := proc "c" (source: u32, type: u32, id: u32, severity: u32, length: i32, message: cstring, userParam: rawptr) {

    if (id == 131169 || id == 131185 || id == 131218 || id == 131204) { return }

    libc.fprintf(libc.stdout,"-------------------------")
    libc.fprintf(libc.stdout,"Debug Message (%d): %s\n", id, message)

    switch source
    {
    case GL.DEBUG_SOURCE_API: libc.fprintf(libc.stdout,"Source: API")
    case GL.DEBUG_SOURCE_WINDOW_SYSTEM: libc.fprintf(libc.stdout,"Source: Window System")
    case GL.DEBUG_SOURCE_SHADER_COMPILER: libc.fprintf(libc.stdout,"Source: Shader Compiler")
    case GL.DEBUG_SOURCE_THIRD_PARTY: libc.fprintf(libc.stdout,"Source: Third Party")
    case GL.DEBUG_SOURCE_APPLICATION: libc.fprintf(libc.stdout,"Source: Application")
    case GL.DEBUG_SOURCE_OTHER: libc.fprintf(libc.stdout,"Source: Other")
    }
    libc.fprintf(libc.stdout,"\n")

    switch type
    {
    case GL.DEBUG_TYPE_ERROR: libc.fprintf(libc.stdout,"Type: Error")
    case GL.DEBUG_TYPE_DEPRECATED_BEHAVIOR: libc.fprintf(libc.stdout,"Type: Deprecated Behaviour")
    case GL.DEBUG_TYPE_UNDEFINED_BEHAVIOR: libc.fprintf(libc.stdout,"Type: Undefined Behaviour")
    case GL.DEBUG_TYPE_PORTABILITY: libc.fprintf(libc.stdout,"Type: Portability")
    case GL.DEBUG_TYPE_PERFORMANCE: libc.fprintf(libc.stdout,"Type: Performance")
    case GL.DEBUG_TYPE_MARKER: libc.fprintf(libc.stdout,"Type: Marker")
    case GL.DEBUG_TYPE_PUSH_GROUP: libc.fprintf(libc.stdout,"Type: Push Group")
    case GL.DEBUG_TYPE_POP_GROUP: libc.fprintf(libc.stdout,"Type: Pop Group")
    case GL.DEBUG_TYPE_OTHER: libc.fprintf(libc.stdout,"Type: Other")
    }
    libc.fprintf(libc.stdout,"\n")

    switch severity
    {
    case GL.DEBUG_SEVERITY_HIGH: libc.fprintf(libc.stdout,"Severity: high")
    case GL.DEBUG_SEVERITY_MEDIUM: libc.fprintf(libc.stdout,"Severity: medium")
    case GL.DEBUG_SEVERITY_LOW: libc.fprintf(libc.stdout,"Severity: low")
    case GL.DEBUG_SEVERITY_NOTIFICATION: libc.fprintf(libc.stdout,"Severity: notification")
    }

    libc.fprintf(libc.stdout,"\n")
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

