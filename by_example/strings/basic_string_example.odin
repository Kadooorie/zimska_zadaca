package basic_string_example

import "core:fmt"
import "core:strings"

/*
	Strings in Odin are immutable.
	 
	Runes are unencoded code points like 0x96EA which get viewed as 雪.
	When you construct a string with runes, they get encoded into a UTF-8 format and stored as an array of bytes.

	You can think of runes as characters, but be careful, as one rune does not always equal one character.
	For example: 👋🏻 produces 2 runes. One for the hand and one for the mask color.
*/
main :: proc() {

	name1 := "雪"
	name2 := "月"

	// Check if the names are equal.
	is_equal := strings.compare(name1, name2)

	if i