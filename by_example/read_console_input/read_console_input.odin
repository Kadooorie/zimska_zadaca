package read_console_input

import "core:fmt"
import "core:os"

main :: proc() {
	buf: [256]byte
	fmt.print