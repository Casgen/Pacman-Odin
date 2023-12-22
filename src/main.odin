package main

import Consts "constants"
import "core:fmt"
import Ent "entities"
import SDL "vendor:sdl2"

App :: struct {
	perf_frequency: f64,
	renderer:       ^SDL.Renderer,
	window:         ^SDL.Window,
}

app := App{}


init :: proc() {
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

	init()

	time_start, time_last: f64 = 0, 0
	timestep: f32 = 0

	nodes: [7]^Ent.Node = Ent.prepare_nodes_test()

	event: SDL.Event
	state: [^]u8
	num_keys: i32

	pacman: Ent.Pacman

	pacman.position = nodes[0].position
    pacman.current_node = nodes[0]
	pacman.speed = 0.1
	pacman.velocity = {0, 0}

	player_rect: SDL.Rect = {i32(pacman.position.x), i32(pacman.position.y), 32, 32}


	game_loop: for {

		time_start = get_time()

		SDL.PollEvent(&event)

		#partial switch event.type {

		case SDL.EventType.QUIT:
			break game_loop

		case SDL.EventType.KEYDOWN:
				Ent.update_control(&pacman)
		}

		Ent.update_pos(&pacman, timestep)

        player_rect.x = i32(pacman.position.x)
        player_rect.y = i32(pacman.position.y)


		SDL.RenderClear(app.renderer)

		SDL.SetRenderDrawColor(app.renderer, 255, 0, 0, 255)
		error: i32 = SDL.RenderFillRect(app.renderer, &player_rect)


		for n in nodes {

			SDL.SetRenderDrawColor(app.renderer, 255, 255, 0, 255)

			for neighbor in n.neighbors {
				if neighbor != nil {
					SDL.RenderDrawLine(
						app.renderer,
						i32(n.position.x),
						i32(n.position.y),
						i32(neighbor^.position.x),
						i32(neighbor^.position.y),
					)
				}
			}

			SDL.SetRenderDrawColor(app.renderer, 123, 211, 0, 255)

			node_rect: SDL.Rect = {i32(n.position.x), i32(n.position.y), 16, 16}
			SDL.RenderFillRect(app.renderer, &node_rect)

		}


		SDL.SetRenderDrawColor(app.renderer, 0, 0, 0, 255)

		SDL.RenderPresent(app.renderer)

		time_last = get_time()

		timestep = f32(time_last - time_start)
	}

	SDL.DestroyRenderer(app.renderer)
	SDL.DestroyWindow(app.window)

	SDL.Quit()

}

get_time :: proc() -> f64 {
	return f64(SDL.GetPerformanceCounter()) * 1000 / f64(app.perf_frequency)
}
