package main

import Consts "constants"
import "core:fmt"
import Ent "entities"
import SDL "vendor:sdl2"

App :: struct {
	perf_frequency: f64,
	renderer:       ^SDL.Renderer,
}

app := App{}

main :: proc() {


	assert(SDL.Init(SDL.INIT_VIDEO | SDL.INIT_JOYSTICK) == 0, SDL.GetErrorString())

	window := SDL.CreateWindow(
		"PacMan",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		Consts.SCREEN_WIDTH,
		Consts.SCREEN_HEIGHT,
		SDL.WINDOW_SHOWN,
	)

	assert(window != nil, SDL.GetErrorString())

	app.renderer = SDL.CreateRenderer(window, -1, SDL.RENDERER_ACCELERATED | SDL.RENDERER_PRESENTVSYNC)

	assert(app.renderer != nil, SDL.GetErrorString())

	SDL.SetHint(SDL.HINT_RENDER_SCALE_QUALITY, "linear")
	app.perf_frequency = f64(SDL.GetPerformanceFrequency())

    fmt.println(u32(SDL.SCANCODE_RIGHT))
    fmt.println(u32(SDL.SCANCODE_LEFT))
    fmt.println(u32(SDL.SCANCODE_UP))
    fmt.println(u32(SDL.SCANCODE_DOWN))

	time_start: f64 = 0
	time_last: f64 = 0
	timestep: f32 = 0


	nodes: [7]^Ent.Node = Ent.prepare_nodes_test()

	event: SDL.Event
	state: [^]u8
	num_keys: i32

	pacman: Ent.Pacman = Ent.init_pacman(f32(nodes[0].position_x), f32(nodes[0].position_y))

	player_rect: SDL.Rect = {i32(pacman.position.x), i32(pacman.position.y), 32, 32}

	game_loop: for {
        
        time_start = get_time()

		SDL.PollEvent(&event)

		#partial switch event.type {

		case SDL.EventType.QUIT:
			break game_loop

		case SDL.EventType.KEYDOWN:
            Ent.update_control(&pacman)
            fmt.println(pacman)

            player_rect.x = i32(pacman.position.x)
            player_rect.y = i32(pacman.position.y)
		}

        Ent.update_pos(&pacman, timestep)


		SDL.RenderClear(app.renderer)

		SDL.SetRenderDrawColor(app.renderer, 255, 0, 0, 255)
		error: i32 = SDL.RenderFillRect(app.renderer, &player_rect)


		for n in nodes {

			// SDL.SetRenderDrawColor(app.renderer, 255, 255, 0, 255)

			for neighbor in n.neighbors {
				if neighbor != nil {
					SDL.RenderDrawLine(
						app.renderer,
						n.position_x,
						n.position_y,
						neighbor^.position_x,
						neighbor^.position_y,
					)
				}
			}

			SDL.SetRenderDrawColor(app.renderer, 123, 211, 0, 255)

			node_rect: SDL.Rect = {n.position_x, n.position_y, 16, 16}
			SDL.RenderFillRect(app.renderer, &node_rect)

		}


		SDL.SetRenderDrawColor(app.renderer, 0, 0, 0, 255)

		SDL.RenderPresent(app.renderer)

        time_last = get_time()

        timestep = f32(time_last - time_start)
	}

	SDL.DestroyRenderer(app.renderer)
	SDL.DestroyWindow(window)
	SDL.Quit()

}

get_time :: proc() -> f64 {
	return f64(SDL.GetPerformanceCounter()) * 1000 / f64(SDL.GetPerformanceFrequency())
}
