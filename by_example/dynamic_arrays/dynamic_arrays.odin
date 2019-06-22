
package dynamic_arrays

import "core:fmt"
import "core:mem"

main :: proc() {
	// Create a dynamic array with a length of 5 and a capacity of 5.
	dyn := make([dynamic]int, 5, 5)
	// dyn = [0, 0, 0, 0, 0]

	// Free the dynamic array.
	defer delete(dyn)

	// Add elements to the dynamic array.
	append(&dyn, 1)
	append(&dyn, 2)
	// dyn = [0, 0, 0, 0, 0, 1, 2]

	// Remove the last element.
	last_element := pop(&dyn)

	// Remove the first element.
	first_element := pop_front(&dyn)
	// dyn = [0, 0, 0, 0, 1]

	// Add an array to the dynamic array.
	arr: [3]int = {1, 2, 3}
	append(&dyn, ..arr[:])

	// Remove what we just added.
	remove_range(&dyn, len(dyn) - len(arr), len(dyn))

	fmt.println(dyn)

	// Zero all the elements.
	mem.zero_slice(dyn[:])
	
	for _, i in dyn {
		dyn[i] = i + 1
	}

	// Maintain the order of the elements.