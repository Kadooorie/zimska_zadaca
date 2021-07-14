
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
	pos:            [2]f32,
	vel:            [2]f32,
	reload_counter: f32,
	bullet_decay:   f32,
	dash_counter:   f32,
}

render_entity :: proc(entity: ^Entity, game: ^Game) {
	switch entity.type {
	case .PLAYER:
		sdl2.SetRenderDrawColor(game.renderer, 255, 0, 255, 0)
		sdl2.RenderDrawRectF(
			game.renderer,
			&sdl2.FRect{x = entity.pos.x, y = entity.pos.y, w = 10, h = 10},
		)
	case .ENEMY:
		sdl2.SetRenderDrawColor(game.renderer, 0, 255, 255, 0)
		sdl2.RenderDrawRectF(
			game.renderer,
			&sdl2.FRect{x = entity.pos.x, y = entity.pos.y, w = 10, h = 10},
		)
	case .PROJECTILE:
		sdl2.SetRenderDrawColor(game.renderer, 0, 255, 255, 0)
		sdl2.RenderDrawPointF(game.renderer, entity.pos.x, entity.pos.y)
	}