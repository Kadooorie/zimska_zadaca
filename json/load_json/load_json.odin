
package load_json

import "core:fmt"
import "core:encoding/json"

import "core:os"

main :: proc() {
	// Load in your json file!
	data, ok := os.read_entire_file_from_filename("game_settings.json")
	if !ok {
		fmt.eprintln("Failed to load the file!")
		return
	}