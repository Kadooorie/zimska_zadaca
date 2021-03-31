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
piece_active := fal