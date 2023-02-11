
package microui_sdl

import "core:fmt"
import "core:c/libc"
import SDL "vendor:sdl2"
import mu "vendor:microui"

state := struct {
	mu_ctx: mu.Context,
	log_buf:         [1<<16]byte,
	log_buf_len:     int,