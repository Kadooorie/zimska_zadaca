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

	if is_equal == 0 {
		fmt.println("The names match!")
	} else {
		fmt.println("The names do not match!")
	}

	// contains_rune will return the index of the rune or -1 if it does not contain the rune.
	name1_index := strings.contains_rune(name1, 'A')
	if name1_index == -1 {
		fmt.println("name_1 does not contain the rune!")
	} else {
		fmt.println("name_1 contains the rune and is located at index:", name1_index)
	}
	
	fmt.println("name1 is", strings.rune_count(name1), "rune(s) long.")

	// Join the two names together separated by a comma!
	list_of_names := strings.join({name1, name2}, ",")
	defer delete(list_of_names)
	fmt.println(list_of_names)

	// Split the list of names into an array of names.
	names