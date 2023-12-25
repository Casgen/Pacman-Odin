package main

import Consts "constants"
import LibC "core:c"
import "core:fmt"
import Ent "entities"
import Level "level"
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

	lvl_data, err := Level.read_level("res/mazetest.txt")
	assert(err == Level.ParseError.None)

	level := Level.parse_level(lvl_data)

	time_start, time_last: f64 = 0, 0
	timestep: f32 = 0

	event: SDL.Event
	state: [^]u8
	num_keys: i32

	pacman: Ent.Pacman

	pacman.position = level.nodes[0].position
	pacman.current_node = level.nodes[0]
	pacman.speed = 0.1
    pacman.collision_radius = 5
	pacman.velocity = {0, 0}
	pacman.target_node = nil
	pacman.direction = Ent.Direction.None

	game_loop: for {

		time_start = get_time()

        // Event handling
		SDL.PollEvent(&event)
		#partial switch event.type {

		case SDL.EventType.QUIT:
			break game_loop

		case SDL.EventType.KEYDOWN:
			Ent.update_control(&pacman, event.key.keysym.scancode)
		}

        // Game Logic
		Ent.update_pos(&pacman, timestep)
        eaten_pellet, index := Ent.try_eat_pellets(&pacman, &level.pellets)

        if eaten_pellet != nil {
            ordered_remove(&level.pellets, index)
        }

        // Rendering
		SDL.RenderClear(app.renderer)

		render_player(&pacman)

		for node in level.nodes {
			render_node(node, {255, 0, 0}, true)
		}

		render_node(pacman.current_node, {0, 121, 255}, false)
		if pacman.target_node != nil {
			render_node(pacman.target_node, {244, 0, 178}, false)
		}

		render_pellets(level.pellets)


		SDL.SetRenderDrawColor(app.renderer, 0, 0, 0, 255)
		SDL.RenderPresent(app.renderer)

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

render_player :: proc(pacman: ^Ent.Pacman) {
	player_rect: SDL.Rect = {i32(pacman.position.x), i32(pacman.position.y), 32, 32}

	SDL.SetRenderDrawColor(app.renderer, 255, 0, 0, 255)
	error: i32 = SDL.RenderFillRect(app.renderer, &player_rect)
}

render_pellets :: proc(pellets: [dynamic]Ent.Pellet) {
	for item in pellets {
		SDL.SetRenderDrawColor(app.renderer, 255, 255, 0, 255)
		rect: SDL.FRect = {item.position.x, item.position.y, f32(item.radius), f32(item.radius)}

		SDL.RenderFillRectF(app.renderer, &rect)
	}
}

render_node :: proc(node: ^Ent.Node, color: [3]u8, render_lines: bool) {

	SDL.SetRenderDrawColor(app.renderer, color[0], color[1], color[2], 255)

	node_rect: SDL.Rect = {i32(node.position.x), i32(node.position.y), 16, 16}
	SDL.RenderFillRect(app.renderer, &node_rect)

	if !render_lines {
		return
	}

	for neighbor in node.neighbors {
		if neighbor != nil {

			if node.is_portal && neighbor.is_portal {
				continue
			}

			SDL.RenderDrawLine(
				app.renderer,
				i32(node.position.x),
				i32(node.position.y),
				i32(neighbor^.position.x),
				i32(neighbor^.position.y),
			)
		}
	}

	SDL.SetRenderDrawColor(app.renderer, 123, 211, 0, 255)

}

