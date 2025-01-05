package game

import "core:mem"
import consts "../constants"
import SDL "vendor:sdl2"
import GL "vendor:OpenGL"
import "core:c/libc"
import "core:time"
import "core:mem/virtual"
import "core:fmt"
import "../logger"
import "../gfx"

GameState :: struct {
	perf_frequency: f64,
	renderer:       ^SDL.Renderer,
	window:         ^SDL.Window,
	gl_context:     SDL.GLContext,

	pacman: ^Pacman,
	axis: AxisProgram,
	ghost: ^Ghost, 
	level: ^Level,
	quad_program: gfx.Program,
	is_running: bool,
}

GameMemory :: struct {
	game_state: GameState,

	permanent_storage: virtual.Arena,
	transient_storage: virtual.Arena,
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

init_sdl_with_gl :: proc(game_memory: ^GameMemory) {

	init_result := SDL.Init(SDL.INIT_VIDEO | SDL.INIT_JOYSTICK | SDL.INIT_EVENTS)

	if (init_result != 0) {
		panic(SDL.GetErrorString())
	}

	SDL.GL_SetAttribute(SDL.GLattr.CONTEXT_PROFILE_MASK, auto_cast (SDL.GLprofile.CORE))
	SDL.GL_SetAttribute(SDL.GLattr.CONTEXT_MAJOR_VERSION, 4)
	SDL.GL_SetAttribute(SDL.GLattr.CONTEXT_MINOR_VERSION, 6)
	SDL.GL_SetAttribute(SDL.GLattr.DOUBLEBUFFER, 1)
	SDL.GL_SetAttribute(SDL.GLattr.DEPTH_SIZE, 24)

	game_memory.game_state.window = SDL.CreateWindow(
		"PacMan",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		consts.SCREEN_WIDTH,
		consts.SCREEN_HEIGHT,
		SDL.WINDOW_SHOWN | SDL.WINDOW_OPENGL | SDL.WINDOW_RESIZABLE,
	)


    GL.load_up_to(4, 6, SDL.gl_set_proc_address)

	assert(game_memory.game_state.window != nil, SDL.GetErrorString())

	game_memory.game_state.gl_context = SDL.GL_CreateContext(game_memory.game_state.window)

	assert(game_memory.game_state.gl_context != nil, SDL.GetErrorString())

	if SDL.GL_SetSwapInterval(1) < 0 {
		fmt.panicf("Failed to set Swap Interval!: %s", SDL.GetErrorString())
	}

    GL.Enable(GL.DEBUG_OUTPUT)
    GL.Enable(GL.DEBUG_OUTPUT_SYNCHRONOUS)
    GL.Enable(GL.BLEND)
    GL.Enable(GL.PROGRAM_POINT_SIZE)
    GL.BlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
    GL.DebugMessageCallback(debug_callback, nil)
}


init :: proc() -> (GameMemory, bool) {
	game_memory := GameMemory{
		game_state = {
			renderer = nil,
			window = nil,
			gl_context = nil
		},
	}

	perm_ok := virtual.arena_init_static(&game_memory.permanent_storage, commit_size=1024 * 10)

	if perm_ok != virtual.Allocator_Error.None {
		logger.log_fatalfl("Failed to initialize an Arena with permanent storage!", #location(perm_ok))
		return game_memory, false
	}

	tran_ok := virtual.arena_init_static(&game_memory.transient_storage, commit_size=mem.Megabyte * 64)

	if tran_ok != virtual.Allocator_Error.None {
		logger.log_fatalfl("Failed to initialize an Arena with permanent storage!", #location(tran_ok))
		return game_memory, false
	}

	init_sdl_with_gl(&game_memory)
	gfx.load_spritesheet("./res/spritesheet.png")


	game_memory.game_state.level = load_level(&game_memory, "res/mazetest.txt")
	game_memory.game_state.is_running = true

	game_memory.game_state.pacman = pacman_create(&game_memory)
	pacman_init(game_memory.game_state.pacman, game_memory.game_state.level.pacman_spawn)

	game_memory.game_state.ghost = ghost_create(&game_memory)
	ghost_init(game_memory.game_state.ghost, game_memory.game_state.level.ghost_spawns[0], {1.0, 1.0})

	game_memory.game_state.axis = create_2d_axis_program()

	game_memory.game_state.quad_program = gfx.create_program("res/shaders/quad")

	return game_memory, true
}

deinit :: proc(game_memory: ^GameMemory) {

	gfx.unbind_program()
	gfx.unbind_texture_2d()
	gfx.destroy_program(&game_memory.game_state.level.pellets_program)
	destroy_axis(&game_memory.game_state.axis)
	gfx.destroy_program(&game_memory.game_state.level.point_program)
	gfx.destroy_program(&game_memory.game_state.quad_program)
	gfx.destroy_spreadsheet()

	virtual.arena_destroy(&game_memory.permanent_storage)
	virtual.arena_destroy(&game_memory.transient_storage)

	SDL.DestroyWindow(game_memory.game_state.window)
	SDL.DestroyRenderer(game_memory.game_state.renderer)
}

// TODO: Gotta figure out, why is it running so fast. Probably left out a piece of code which made the
// game run at a fixed rate. Gotta integrate that. Also, the algorithm for finding next nodes in the ghost
// seems to be not work properly. Probably not enough time to stay in one of the states for a long time
update :: proc(game_memory: ^GameMemory, delta_time: ^f32) {
	
	game_state := &game_memory.game_state

	event: SDL.Event
	state: [^]u8

	start_time := time.now()._nsec

	// Don't forget to call PollEvent in a while loop!
	// Otherwise, the events won't register immediately when focusing the window.
	for (SDL.PollEvent(&event) == true) {

		#partial switch event.type {

			case SDL.EventType.QUIT:
				game_state.is_running = false
			case SDL.EventType.KEYDOWN:
				key := event.key.keysym.scancode

				switch {
					case key >= SDL.Scancode.RIGHT && key <= SDL.Scancode.UP:
						update_direction(game_state.pacman, event.key.keysym.scancode)
					case key == SDL.Scancode.F4 && event.key.keysym.mod == SDL.KMOD_LALT:
						game_state.is_running = false
				}
		}
	}

	pacman_update_pos(game_state.pacman, delta_time^)
	pellet, i := try_eat_pellets(game_state.pacman, game_state.level.pellets)

	if pellet != nil {
		set_visibility(pellet, i, game_state.level.pellets_ssbo, false)
		fmt.println("Eaten!")
	}

	ghost_update(game_state.ghost, game_state.pacman.position, delta_time^)

	GL.Clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

	// gfx.ogl_draw_debug_points(len(game_state.level.nodes), game_state.level.node_vao_id, game_state.point_program.id) 

	draw_maze(&game_state.level.maze)

	GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, game_state.level.pellets_ssbo.id)
	GL.BindBufferBase(GL.SHADER_STORAGE_BUFFER, 0, game_state.level.pellets_ssbo.id)
	gfx.ogl_draw_debug_points(
		len(game_state.level.pellets),
		game_state.level.pellets_vao_id,
		game_state.level.pellets_program.id
	) 

	ogl_debug_render_player(game_state.pacman, &game_state.quad_program)
	ogl_debug_render_ghost(game_state.ghost, &game_state.quad_program)

	draw_axis(&game_state.axis)

	SDL.GL_SwapWindow(game_state.window)

	delta_time^ = f32((time.now()._nsec - start_time) / 1_000_000)
}

