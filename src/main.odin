package main

import Consts "constants"
import LibC "core:c"
import "core:fmt"
import "entities"
import Level "level"
import SDL "vendor:sdl2"
import "gfx"

App :: struct {
	perf_frequency: f64,
	renderer:       ^SDL.Renderer,
	window:         ^SDL.Window,
	gl_context:     rawptr,
}

app := App{}

WITH_OPENGL :: true


init_sdl :: proc() {
	assert(SDL.Init(SDL.INIT_VIDEO | SDL.INIT_JOYSTICK) == 0, SDL.GetErrorString())

	app.window = SDL.CreateWindow(
		"PacMan",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		Consts.SCREEN_WIDTH,
		Consts.SCREEN_HEIGHT,
		SDL.WINDOW_SHOWN,
	)

	assert(app.window != nil, SDL.GetErrorString())

	app.renderer = SDL.CreateRenderer(
		app.window,
		-1,
		SDL.RENDERER_ACCELERATED | SDL.RENDERER_PRESENTVSYNC,
	)

	assert(app.renderer != nil, SDL.GetErrorString())

	SDL.SetHint(SDL.HINT_RENDER_SCALE_QUALITY, "linear")
	app.perf_frequency = f64(SDL.GetPerformanceFrequency())

}


main :: proc() {

	when WITH_OPENGL {
		run_with_opengl()
	} else {
		run_default()
	}

}

run_default :: proc() {

	init_sdl()

	level := Level.load_level("res/mazetest.txt")

	time_start, time_last: f64 = 0, 0
	timestep: f32 = 0

	event: SDL.Event
	state: [^]u8
	num_keys: i32

	pacman := entities.create_pacman(level.nodes[0])
	ghost := entities.create_ghost(level.nodes[1], {0, 0})


	game_loop: for {

		time_start = get_time()

		// Event handling
		SDL.PollEvent(&event)
		#partial switch event.type {

		case SDL.EventType.QUIT:
			break game_loop

		case SDL.EventType.KEYDOWN:
			entities.update_control(&pacman, event.key.keysym.scancode)
		}

		// Game Logic
		entities.update_ghost_ai(&ghost, pacman.position, timestep)
		entities.update_pacman_pos(&pacman, timestep)
		entities.try_eat_pellets(&pacman, &level.pellets, true)

		// Rendering
		{
			SDL.RenderClear(app.renderer)

			entities.debug_render_ghost(app.renderer, &ghost)
			entities.debug_render_player(app.renderer, &pacman)

			for node in level.nodes {
				entities.debug_render_node(app.renderer, node, {255, 0, 0}, true)
			}

			entities.debug_render_node(app.renderer, pacman.current_node, {0, 121, 255}, false)
			if pacman.target_node != nil {
				entities.debug_render_node(app.renderer, pacman.target_node, {244, 0, 178}, false)
			}

			entities.render_pellets(app.renderer, level.pellets)


			SDL.SetRenderDrawColor(app.renderer, 0, 0, 0, 255)
			SDL.RenderPresent(app.renderer)
		}
		time_last = get_time()

		timestep = f32(time_last - time_start)
	}

	SDL.DestroyRenderer(app.renderer)
	SDL.DestroyWindow(app.window)

	SDL.Quit()

	Level.destroy_level(level)

}

get_time :: proc() -> f64 {
	return f64(SDL.GetPerformanceCounter()) * 1000 / f64(app.perf_frequency)
}
