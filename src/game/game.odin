package game

import "core:mem"
import SDL "vendor:sdl2"
import GL "vendor:OpenGL"
import "core:c/libc"
import "core:time"
import "core:mem/virtual"
import "core:fmt"
import "core:log"
import "../gfx"

GameState :: struct {
	perf_frequency: f64,
	renderer:       ^SDL.Renderer,
	window:         ^SDL.Window,
	gl_context:     SDL.GLContext,

	axis: AxisProgram,
	quad_program: gfx.Program, player: ^Player, is_running: bool,
	camera: ^Camera,
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

init_sdl_with_gl :: proc() -> (window: ^SDL.Window, gl_context: SDL.GLContext) {

	init_result := SDL.Init(SDL.INIT_VIDEO | SDL.INIT_JOYSTICK | SDL.INIT_EVENTS)

	if (init_result != 0) {
		panic(SDL.GetErrorString())
	}

	SDL.GL_SetAttribute(SDL.GLattr.CONTEXT_PROFILE_MASK, auto_cast (SDL.GLprofile.CORE))
	SDL.GL_SetAttribute(SDL.GLattr.CONTEXT_MAJOR_VERSION, 4)
	SDL.GL_SetAttribute(SDL.GLattr.CONTEXT_MINOR_VERSION, 6)
	SDL.GL_SetAttribute(SDL.GLattr.DOUBLEBUFFER, 1)
	SDL.GL_SetAttribute(SDL.GLattr.DEPTH_SIZE, 24)

	window = SDL.CreateWindow("PacMan", SDL.WINDOWPOS_CENTERED, SDL.WINDOWPOS_CENTERED, 1920, 1080,
		SDL.WINDOW_SHOWN | SDL.WINDOW_OPENGL | SDL.WINDOW_RESIZABLE,)

	if window == nil {
		error_msg := SDL.GetError()
		log.fatalf("Failed to create an SDL window! %s", error_msg)
		panic("Failed to create an SDL Window!")
	}

    GL.load_up_to(4, 6, SDL.gl_set_proc_address)

	assert(window != nil, SDL.GetErrorString())

	gl_context = SDL.GL_CreateContext(window)
	
	if gl_context == nil {
		error_msg := SDL.GetError()
		log.fatalf("Failed to create an OpenGL context! %s", error_msg)
		panic("Failed to create an OpenGL context!")
	}

	assert(gl_context != nil, SDL.GetErrorString())

	if SDL.GL_SetSwapInterval(1) < 0 {
		fmt.panicf("Failed to set Swap Interval!: %s", SDL.GetErrorString())
	}

    GL.Enable(GL.DEBUG_OUTPUT)
    GL.Enable(GL.DEBUG_OUTPUT_SYNCHRONOUS)
    GL.Enable(GL.BLEND)
    GL.Enable(GL.PROGRAM_POINT_SIZE)
    GL.BlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
    GL.DebugMessageCallback(debug_callback, nil)

	return
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
		log.fatal("Failed to initialize an Arena with permanent storage!")
		return game_memory, false
	}

	tran_ok := virtual.arena_init_static(&game_memory.transient_storage, commit_size=mem.Megabyte * 64)

	if tran_ok != virtual.Allocator_Error.None {
		log.fatal("Failed to initialize an Arena with permanent storage!")
		return game_memory, false
	}

	window, gl_context := init_sdl_with_gl()
	game_memory.game_state.window = window
	game_memory.game_state.gl_context = gl_context

	gfx.load_spritesheet("./res/spritesheet.png")
	game_memory.game_state.is_running = true

	game_memory.game_state.player, _ = arena_push_struct(&game_memory.transient_storage, Player)
	player_init(game_memory.game_state.player)

	game_memory.game_state.axis = create_2d_axis_program()
	game_memory.game_state.quad_program = gfx.create_program("res/shaders/quad")

	width, height: i32
	SDL.GetWindowSize(game_memory.game_state.window, &width, &height)
	game_memory.game_state.camera = camera_create(&game_memory, width, height)

	return game_memory, true
}

deinit :: proc(game_memory: ^GameMemory) {

	gfx.unbind_program()
	gfx.unbind_texture_2d()
	destroy_axis(&game_memory.game_state.axis)
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
	GL.Clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

	start_time := time.now()._nsec

	// Don't forget to call PollEvent in a while loop!
	// Otherwise, the events won't register immediately when focusing the window.
	for (SDL.PollEvent(&event) == true) {

		#partial switch event.type {

			case SDL.EventType.QUIT:
				game_state.is_running = false
			case SDL.EventType.KEYDOWN:
			    if event.key.keysym.scancode == SDL.Scancode.F4 && event.key.keysym.mod == SDL.KMOD_LALT {
					game_state.is_running = false
                }
                player_handle_input(game_state.player, &event)
			case SDL.EventType.KEYUP:
                player_handle_input(game_state.player, &event)
			case SDL.EventType.WINDOWEVENT:
				window_event := event.window

				switch {
					case window_event.event == SDL.WindowEventID.RESIZED:
						width: i32
						height: i32
						SDL.GetWindowSize(game_memory.game_state.window, &width, &height)
						camera_update_resolution(game_state.camera,	width, height)
				}
		}
	}
	
	player_update(game_state.player, delta_time^)

	gfx.bind_buffer(&game_state.camera.ubo)
	gfx.bind_buffer_base(&game_state.camera.ubo, 0)

	// TODO: render the player
	gfx.bind_program(game_state.quad_program.id)

	gfx.bind_quad(&game_state.player.quad)

    gfx.set_uniform_2f(&game_state.quad_program, "u_Scale", game_state.player.scale)
    gfx.set_uniform_2f(&game_state.quad_program, "u_Position", game_state.player.position)

	gfx.draw_quad(&game_state.player.quad, game_state.quad_program.id)

	draw_axis(&game_state.axis)

	SDL.GL_SwapWindow(game_state.window)

	delta_time^ = f32((time.now()._nsec - start_time) / 1_000_000)


}

