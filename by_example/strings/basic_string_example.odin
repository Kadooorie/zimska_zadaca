package basic_string_example

import "core:fmt"
import "core:strings"

/*
	Strings in Odin are immutable.
	 
	Runes are unencoded code points like 0x96EA which get viewed as 雪.
	When you construct a string with runes, they get encoded into a UTF-8 format an