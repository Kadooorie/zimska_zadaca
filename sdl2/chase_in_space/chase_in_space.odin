
/*
	Simple game about enemies chasing and shooting you in 2D space.

	Original repo: https://github.com/wbogocki/Odin-Play

	To play:
		- Move with WSAD or arrow keys
		- Jump with Shift + direction
*/

package chase_in_space

import "core:fmt"
import "core:math/linalg"
import "vendor:sdl2"

Game :: struct {
	renderer: ^sdl2.Renderer,
	keyboard: []u8,
	time:     f64,
	dt:       f64,
	entities: [dynamic]Entity,
}

EntityType :: enum {
	PLAYER,
	ENEMY,
	PROJECTILE,
}

Entity :: struct {
	type:           EntityType,
	hp:             int,