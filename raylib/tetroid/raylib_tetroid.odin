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
