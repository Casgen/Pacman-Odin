package gfx

import "core:fmt"
import "core:os"
import GL "vendor:OpenGL"
import "core:strings"
import "core:path/filepath"
import sa "core:container/small_array"
import "core:math/linalg"

ShaderError :: enum {
	None,
	Couldnt_Read_File,
    Failed_To_Compile,
}



Program :: struct {
	id:   u32,
    uniform_map: map[cstring]i32
}

Shader :: struct {
    id: u32,
    type: u32
}

evaluate_shader_type :: proc{
    evaluate_shader_type_u32,
    evaluate_shader_type_ext,
}

evaluate_shader_type_u32 :: proc(type: u32) -> string {
    switch type {
        case GL.VERTEX_SHADER: return "Vertex Shader"
        case GL.FRAGMENT_SHADER: return "Fragment Shader"
        case GL.GEOMETRY_SHADER: return "Geometry Shader"
        case GL.COMPUTE_SHADER: return "Compute Shader"
        case GL.TESS_EVALUATION_SHADER: return "Tesselation evalutation Shader"
        case GL.TESS_CONTROL_SHADER: return "Tesselation control Shader"
        case : return "RECOGNIZE_ERROR"
    }

}

evaluate_shader_type_ext :: proc(ext: string) -> u32 {
    switch ext {
        case ".vert": return GL.VERTEX_SHADER
        case ".frag": return GL.FRAGMENT_SHADER
        case ".geom": return GL.GEOMETRY_SHADER
        case ".comp": return GL.COMPUTE_SHADER
        case ".tese": return GL.TESS_EVALUATION_SHADER
        case ".tesc": return GL.TESS_CONTROL_SHADER
        case : return 0
    }

}

create_program :: proc(shader_dir_path: string) -> Program  {

    buffer_id: u32

    program: Program
    program.id = GL.CreateProgram()

    dir_handle, open_err := os.open(shader_dir_path)

    if open_err != 0 {
        fmt.panicf("Error opening the shader dir!: %d", open_err)
    }

    new_shaders: sa.Small_Array(6, Shader)

    file_infos, read_err := os.read_dir(dir_handle, 6)

    if read_err != 0 {
        fmt.panicf("Error reading the shader dir!: %d", open_err)
    }

    for info in file_infos {
        shader_type := evaluate_shader_type(filepath.ext(info.fullpath))

        if shader_type == 0 {
            fmt.println("Skipping %s", info.fullpath)
        }

        shader, ok := create_shader(info.fullpath, shader_type)
        assert(ok == .None)
        sa.append(&new_shaders, shader)

        GL.AttachShader(program.id, shader.id)
    }

    GL.LinkProgram(program.id)
    GL.ValidateProgram(program.id)

    for i := 0; i < new_shaders.len; i += 1 {
        shader := sa.get(new_shaders, i)
        GL.DeleteShader(shader.id)
    }

    os.close(dir_handle)


    return program
}

create_shader :: proc(shader_path: string, shader_type: u32) -> (Shader, ShaderError) {

    shader: Shader

    shader.id = GL.CreateShader(shader_type)
    shader.type  = shader_type

    shader_file, read_ok := os.read_entire_file(shader_path)
	defer delete(shader_file)

    cstring_content := strings.clone_to_cstring(transmute(string)shader_file)
	defer delete(cstring_content)

    if !read_ok {
        fmt.eprintf("Failed to read file!: %s", shader_path)
        return {}, .Couldnt_Read_File
    }

    GL.ShaderSource(shader.id, 1, &cstring_content, nil)
    GL.CompileShader(shader.id)

    result: i32

    GL.GetShaderiv(shader.id, GL.COMPILE_STATUS, &result)

    if bool(result) == GL.FALSE {
        
        length: i32
        GL.GetShaderiv(shader.id, GL.INFO_LOG_LENGTH, &length)

        message := make([^]u8, length)
        defer free(message)

        GL.GetShaderInfoLog(shader.id, length, &length, message)

        fmt.eprintf("%s failed to compile!: \n%s Path: %s\n", evaluate_shader_type(shader_type), shader_path,  message)

        GL.DeleteShader(shader.id)

        return {}, .Failed_To_Compile
    }

    return shader, .None
    
}

get_uniform_location :: proc(using program: ^Program, name: cstring) -> i32 {
    location, ok := program.uniform_map[name]

    if ok {
        return location
    }

    new_location := GL.GetUniformLocation(program.id, cstring(name))

    if location == -1 {
        fmt.eprintf("Warning: Uniform %s was not found!", name)
    }

    program.uniform_map[name] = new_location
    return new_location
}

set_uniform_1i :: proc {
    set_uniform_1i_i32,
    set_uniform_1i_int,
}

set_uniform_1i_i32 :: proc(using program: ^Program, name: cstring, value: i32) {
    GL.Uniform1i(get_uniform_location(program, name), value)
}

set_uniform_1i_int :: proc(using program: ^Program, name: cstring, value: int) {
    GL.Uniform1i(get_uniform_location(program, name), i32(value))
}

set_uniform_1u_u32 :: proc(using program: ^Program, name: cstring, value: u32) {
    GL.Uniform1ui(get_uniform_location(program, name), (value))
}

set_uniform_2u_u32 :: proc(using program: ^Program, name: cstring, v0: u32, v1: u32) {
    GL.Uniform2ui(get_uniform_location(program, name), v0, v1)
}


set_uniform_2f :: proc {
    set_uniform_2f_float,
    set_uniform_2f_vec,
}

set_uniform_1f :: proc(using program: ^Program, name: cstring, value: f32) {
    GL.Uniform1f(get_uniform_location(program, name), value)
}

set_uniform_2f_float :: proc(using program: ^Program, name: cstring, value_1: f32, value_2: f32 ) {
    GL.Uniform2f(get_uniform_location(program, name), value_1, value_2)
}

set_uniform_2f_vec :: proc(using program: ^Program, name: cstring, vec: linalg.Vector2f32) {
    GL.Uniform2f(get_uniform_location(program, name), vec.x, vec.y)
}

bind_program :: proc {
	bind_program_struct,
	bind_program_id,
}

bind_program_struct :: proc(using program: ^Program) {
	GL.UseProgram(program.id)
}

bind_program_id :: proc(id: u32) {
	GL.UseProgram(id)
}

unbind_program :: proc() {
	GL.UseProgram(0)
}

destroy_program :: proc(using program: ^Program) {
	GL.DeleteProgram(program.id)
	delete(program.uniform_map)
}

dispatch_compute :: #force_inline proc(num_groups_x, num_groups_y, num_groups_z: u32) {
	GL.DispatchCompute(num_groups_x, num_groups_y, num_groups_z)
}

memory_barrier :: #force_inline proc(barriers: u32) {
	GL.MemoryBarrier(barriers)
}
