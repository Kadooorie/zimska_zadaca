package main


/*******************************************************************************************
*
*   raylib - classic game: tetroid
*
*   Sample game developed by Marc Palau and Ramon Santamaria
*
*   This game has been created using raylib v1.3 (www.raylib.com)
*   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
*
*  Translation from https://github.com/raysan5/raylib-games/blob/master/classics/src/tetris.c to Odin
*
*   Copyright (c) 2015 Ramon Santamaria (@raysan5)
*   Copyright (c) 2021 Ginger Bill
*
********************************************************************************************/



import rl "vendor:raylib"

SQUARE_SIZE             :: 20

GRID_HORIZONTAL_SIZE    :: 12
GRID_VERTICAL_SIZE      :: 20

LATERAL_SPEED           :: 10
TURNING_SPEED           :: 12
FAST_FALL_AWAIT_COUNTER :: 30

FADING_TIME             :: 33

SCREEN_WIDTH  :: 800
SCREEN_HEIGHT :: 450

Grid_Square :: enum u8 {
	Empty,
	Moving,
	Full,
	Block,
	Fading,
}

game_over := false
pause := false

grid:           [GRID_HORIZONTAL_SIZE][GRID_VERTICAL_SIZE]Grid_Square
piece:          [4][4]Grid_Square
incoming_piece: [4][4]Grid_Square

piece_position: [2]i32

fading_color: rl.Color

begin_play := true
piece_active := false
detection := false
line_to_delete := false

level := 1
lines := 0

gravity_movement_counter := 0
lateral_movement_counter := 0
turn_movement_counter := 0
fast_fall_movement_counter := 0

fade_line_counter := 0

inverse_gravity_speed := 30



main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Tetroid")
	defer rl.CloseWindow()   
	
	init_game()

	rl.SetTargetFPS(60)      

	for !rl.WindowShouldClose() { // Detect window close button or ESC key
		update_game()
		draw_game()
	}
}


init_game :: proc() {
	level = 1
	lines = 0

	fading_color = rl.GRAY

	piece_position = {0, 0}

	pause = false

	begin_play     = true
	piece_active   = false
	detection      = false
	line_to_delete = false

	// Counters
	gravity_movement_counter = 0
	lateral_movement_counter = 0
	turn_movement_counter = 0
	fast_fall_movement_counter = 0

	fade_line_counter = 0
	inverse_gravity_speed = 30

	grid = {}
	incoming_piece = {}

	// Initialize grid matrices
	for i in 0..<GRID_HORIZONTAL_SIZE {
		for j in 0..<GRID_VERTICAL_SIZE {
			switch {
			case j == GRID_VERTICAL_SIZE - 1,
			     i == GRID_HORIZONTAL_SIZE - 1,
			     i == 0:
				grid[i][j] = .Block
			}
		}
	}
}

update_game :: proc() {
	if game_over {
		if rl.IsKeyPressed(.ENTER) {
			init_game()
			game_over = false
		}
		return
	}
	
	if rl.IsKeyPressed(.P) {
		pause = !pause
	}
	
	if pause {
		return
	}
	
	if line_to_delete {
		fade_line_counter += 1
		
		if fade_line_counter % 8 < 4 {
			fading_color = rl.MAROON
		} else {
			fading_color = rl.GRAY
		}
		
		if fade_line_counter >= FADING_TIME {
			delete_complete_lines()
			fade_line_counter = 0
			line_to_delete = false
			
			lines += 1
		}
		return
	}
	
	
	if !piece_active {
		piece_active = create_piece()
		fast_fall_movement_counter = 0
	} else {
		fast_fall_movement_counter += 1