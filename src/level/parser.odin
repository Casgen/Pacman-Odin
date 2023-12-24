package level

import "core:fmt"
import "core:os"
import "core:strings"

ParseError :: enum {
    None,
	Bad_Char,
	Couldnt_Read,
	Couldnt_Split,
	Bad_Format,
}

char_map := map[u8]ObjectType {
	'X' = ObjectType.Block,
	'+' = ObjectType.Node,
	'.' = ObjectType.Empty_Space,
    '=' = ObjectType.Ghost_Gate
}


parse_level :: proc(filename: string) -> (LevelData, ParseError) {
	file, read_ok := os.read_entire_file(filename, context.allocator)

	if !read_ok {
		return LevelData{}, .Couldnt_Read
	}

	str_data := string(file)

	lines, split_ok := strings.split_lines(str_data)

	if split_ok != nil {
		return LevelData{}, .Couldnt_Split
	}

    num_chars := 0

    for i in 0..<len(lines) {
        new_line, was_alloc := strings.remove_all(lines[i]," ")
        lines[i] = new_line

        num_chars += len(new_line)
    }

	row_count := len(lines) - 1
	col_count := num_chars / row_count

	if num_chars % row_count != 0 || num_chars % col_count != 0 {
		return LevelData{}, .Bad_Format
	}

	level_data: LevelData = {{}, row_count, col_count}

	reserve(&level_data.data, num_chars)

	for line in lines {
		// Characters in a string are represented as []rune!
		for index in 0 ..< len(line) {
            rune: u8 = line[index]
            obj_type, ok := char_map[rune]

            if !ok {
		        return LevelData{}, .Bad_Char
            }

	 		append(&level_data.data, u8(char_map[line[index]]))
		}
	}

    delete(file)
    delete(lines)

	return level_data, .None

}
