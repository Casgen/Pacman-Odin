package entities

import "core:math/linalg"
import "core:math/rand"

Ghost :: struct {
    using entity: ^Entity,
    color: [3]u8
}


update_ghost_ai :: proc(ghost: ^Ghost, dt: f32) {

	if ghost.target_node != nil {

		ghost.position += dt * ghost.velocity * ghost.speed

        path_distance := linalg.vector_length2(ghost.current_node.position - ghost.target_node.position)
        distance_to_node := linalg.vector_length2(ghost.current_node.position - ghost.position) 

		if path_distance > distance_to_node {
            return
		}

        if ghost.target_node.is_portal {
            ghost.current_node = ghost.target_node.neighbors[Direction.Portal]
            ghost.target_node = ghost.current_node.neighbors[ghost.direction]
            ghost.position = ghost.current_node.position
            return
        }

        // Find new direction
        valid_directions := get_valid_directions(ghost.target_node)

        random_val := u32(rand.float32() * f32(len(valid_directions)))
        random_dir := valid_directions[random_val]

        next_node := ghost.target_node.neighbors[random_dir]

        if next_node == ghost.current_node && len(valid_directions) > 1 {

            // offset the index by 1 with respect to the array bounds
            random_dir = valid_directions[(random_val + 1) % u32(len(valid_directions))]
            next_node = ghost.target_node.neighbors[random_dir]
        }


        ghost.position = ghost.target_node.position
        ghost.current_node = ghost.target_node
        ghost.target_node = next_node
        ghost.direction = random_dir
        ghost.velocity = velocity_map[random_dir]

        return
	}

    assert(ghost.current_node != nil)

    valid_directions := get_valid_directions(ghost.current_node)
    random_dir := Direction(rand.float32() * f32(len(valid_directions)))

    next_node := ghost.current_node.neighbors[random_dir]

    ghost.position = ghost.current_node.position
    ghost.target_node = next_node
    ghost.direction = random_dir
    ghost.velocity = velocity_map[random_dir]
}




