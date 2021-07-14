
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
}

find_entity :: proc(type: EntityType, game: ^Game) -> ^Entity {
	for _, i in game.entities {
		if game.entities[i].type == type {
			return &game.entities[i]
		}
	}
	return nil
}

update_entity :: proc(entity: ^Entity, game: ^Game) {
	dt := f32(game.dt)
	switch entity.type {
	case .PLAYER:
		dir := [2]f32{0, 0}
		if b8(game.keyboard[sdl2.SCANCODE_UP   ]) | b8(game.keyboard[sdl2.SCANCODE_W]) do dir.y -= 1
		if b8(game.keyboard[sdl2.SCANCODE_DOWN ]) | b8(game.keyboard[sdl2.SCANCODE_S]) do dir.y += 1
		if b8(game.keyboard[sdl2.SCANCODE_LEFT ]) | b8(game.keyboard[sdl2.SCANCODE_A]) do dir.x -= 1
		if b8(game.keyboard[sdl2.SCANCODE_RIGHT]) | b8(game.keyboard[sdl2.SCANCODE_D]) do dir.x += 1
		dir = linalg.normalize0(dir)
		entity.pos += dir * 0.2 * dt
		// Dash
		if b8(game.keyboard[sdl2.SCANCODE_LSHIFT]) && entity.dash_counter == 0 && dir != 0 {
			entity.vel = dir * 5.0
			entity.dash_counter += 150
		} else {
			entity.dash_counter = max(entity.dash_counter - dt, 0)
		}
		entity.pos += entity.vel * dt
		entity.vel -= entity.vel * 0.9999 / dt
		// Keep it in the map
		entity.pos.x = clamp(entity.pos.x, 0, 640 - 10)
		entity.pos.y = clamp(entity.pos.y, 0, 480 - 10)
	case .ENEMY:
		// Towards player