package gfx

import GL "vendor:OpenGL"
import "core:math"
import "core:log"
import lg "core:math/linalg"


UBOVariable :: struct {
	offset, size: u32
}

UBOUniformProps :: struct {
	size, alignment : u32 // In Bytes
}

// Provides information about different base alignments for the alignment of
// uniform variables inside a Uniform Buffer Object.
@private
std_140_alignment := map[typeid]UBOUniformProps {
	typeid_of(f32)				= {4,1 * 4}, // {Size, Base Alignment (N) * 4 bytes}
	typeid_of(bool)				= {4,1 * 4},
	typeid_of(int)				= {4,1 * 4},
	typeid_of(i32)				= {4,1 * 4},
	typeid_of(u32)				= {4,1 * 4},
	typeid_of(f64)				= {8,2 * 4},

	typeid_of(lg.Vector2f32)	= {8,2 * 4},
	typeid_of(lg.Vector3f32)	= {16,4 * 4},
	typeid_of(lg.Vector4f32)	= {16,4 * 4},

	typeid_of(lg.Matrix4x4f64)	= {64,4 * 4},
	typeid_of(lg.Matrix4f64)	= {64,4 * 4},
	typeid_of(matrix[4, 4]f32)	= {64,4 * 4},

	typeid_of(lg.Matrix3x3f64)	= {64,4 * 4},
	typeid_of(lg.Matrix3f64)	= {64,4 * 4},
	typeid_of(matrix[3, 3]f32)	= {64,4 * 4},
}


UBO :: struct {
	using buffer: Buffer,
	size: u32,
	uniform_map: map[string]UBOVariable,
}

// Creates and allocates with a given size a Uniform Buffer Object.
ubo_create :: proc(size: u32, usage: u32 = GL.STATIC_DRAW) -> UBO {
    ubo: UBO
    ubo.target = GL.UNIFORM_BUFFER

	GL.GenBuffers(1, &ubo.id)
	GL.BindBuffer(GL.UNIFORM_BUFFER, ubo.id)
	GL.BufferData(GL.UNIFORM_BUFFER, int(size), nil, usage)
	GL.BindBuffer(GL.UNIFORM_BUFFER, 0)

	return ubo
}

// Adds a uniform variable to the uniform buffer object and properly aligns it.
// **Don't forget to put them in the order which they are defined in the shader**!
// If given a value with a type, which can not be retrieved in the map, it ignores the variable.
// 
// If you want to set a uniform variable as an array (for ex. array of floats). Use the count param
// TODO: Probably check later if it works properly
ubo_add_uniform :: proc(ubo: ^UBO, u_name: string, $T: typeid) {

	u_props, ok := std_140_alignment[T]

	if !ok {
		log.errorf(`Couldn't find the given UBO Variable base alignment and offset!
			Either it can not be supported or has not added! Given type %v`, typeid_of(T))
		return
	}

	u_offset: u32 = 0

	if (u_props.alignment == 4) {
		u_offset = ubo.size
	} else {
		u_offset = u32(math.ceil(f32(ubo.size) / (f32(u_props.alignment)))) * u_props.alignment
	}
	
	ubo.uniform_map[u_name] = {
		size = u_props.size,
		offset = u_offset
	}

	ubo.size = u_offset + u_props.size
}

ubo_add_uniform_array :: proc(ubo: ^UBO, u_name: string, $T: typeid, count: u32) {

	u_props, ok := std_140_alignment[T]

	if !ok {
		log.errorf(`Couldn't find the given UBO Variable base alignment and offset!
			Either it can not be supported or has not added! Given type %v`, typeid_of(T))
		return
	}

	// std140 sets the base alignment of arrays of scalars, vectors or matrices to 4N = 16 bytes
	u_offset := u32(math.ceil(f32(ubo.size) / 16.0)) * 16.0
	
	ubo.uniform_map[u_name] = {
		size = u_props.size * count,
		offset = u_offset
	}

	ubo.size = u_offset + u_props.size * count
}

// Sets or updates the uniform variable inside the UBO. **Note that it automatically binds and unbinds the buffer for you!**
ubo_set_uniform_by_val :: proc(ubo: ^UBO, u_name: string, value: $T) {

	u_variable, ok := ubo.uniform_map[u_name]

	if !ok {
		log.errorf("Couldn't update the desired uniform variable in the UBO: \"%s\" was not found!", u_name)
		return
	}

	GL.BindBuffer(GL.UNIFORM_BUFFER, ubo.id)
	GL.BufferSubData(GL.UNIFORM_BUFFER, int(u_variable.offset), int(u_variable.size), &value)
	GL.BindBuffer(GL.UNIFORM_BUFFER, 0)
}

// Sets or updates the uniform variable inside the UBO. **Note that it automatically binds and unbinds the buffer for you!**
ubo_set_uniform_by_ptr :: proc(ubo: ^UBO, u_name: string, value: ^$T) {

	u_variable, ok := ubo.uniform_map[u_name]

	if !ok {
		log.errorf("Couldn't update the desired uniform variable in the UBO: \"%s\" was not found!", u_name)
		return
	}

	GL.BindBuffer(GL.UNIFORM_BUFFER, ubo.id)
	GL.BufferSubData(GL.UNIFORM_BUFFER, int(u_variable.offset), int(u_variable.size), value)
	GL.BindBuffer(GL.UNIFORM_BUFFER, 0)
}
