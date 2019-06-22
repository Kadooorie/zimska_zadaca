package main 

import "core:fmt"
import "core:os"

main :: proc() {
	// os.args is a []string
	fmt.println(os.args