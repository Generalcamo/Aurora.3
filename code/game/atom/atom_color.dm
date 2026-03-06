/*
	Atom Colour Priority System
	A System that gives finer control over which atom colour to colour the atom with.
	The "highest priority" one is always displayed as opposed to the default of
	"whichever was set last is displayed"

	It can also be used for color filters, since some effects (using non-RGB space matrices)
	are impossible to achieve with just the color variable
*/

/atom
	/**
	 * used to store the different colors on an atom
	 *
	 * its inherent color, the colored paint applied on it, special color effect etc...
	 */
	var/list/atom_colors
	/// Currently used color filter - cached because its applied to all of our overlays because BYOND is horrific
	var/list/cached_color_filter

///Adds an instance of color_type to the atom's atom_colors list
/atom/proc/add_atom_color(coloration, color_priority)
	if(!atom_colors || !length(atom_colors))
		atom_colors = list()
		atom_colors.len = COLOR_PRIORITY_AMOUNT //four priority levels currently.
	if(!coloration)
		return
	if(color_priority > length(atom_colors))
		return
	var/color_type = ATOM_COLOR_TYPE_NORMAL
	if (islist(coloration))
		var/list/color_matrix = coloration
		if (color_matrix["type"] == "color")
			color_type = ATOM_COLOR_TYPE_FILTER
	atom_colors[color_priority] = list(coloration, color_type)
	update_atom_color()

///Removes an instance of color_type from the atom's atom_colors list
/atom/proc/remove_atom_color(color_priority, coloration)
	if(!atom_colors)
		return
	if(color_priority > length(atom_colors))
		return
	if(coloration && atom_colors[color_priority])
		if (atom_colors[color_priority][ATOM_COLOR_TYPE_INDEX] == ATOM_COLOR_TYPE_NORMAL)
			if (atom_colors[color_priority][ATOM_COLOR_VALUE_INDEX] != coloration)
				return //if we don't have the expected color (for a specific priority) to remove, do nothing
		else
			if (!islist(coloration) || !compare_list(coloration, atom_colors[color_priority][ATOM_COLOR_VALUE_INDEX]["color"]))
				return
	atom_colors[color_priority] = null
	update_atom_color()

/**
 * Checks if this atom has the passed color
 * Can optionally be supplied with a range of priorities, IE only checking "washable" or above
 */
/atom/proc/is_atom_color(looking_for_color, min_priority_index = 1, max_priority_index = COLOR_PRIORITY_AMOUNT)
	// make sure uppertext hex strings don't mess with LOWER_TEXT hex strings
	if (!islist(looking_for_color))
		looking_for_color = LOWER_TEXT(looking_for_color)

	if(!LAZYLEN(atom_colors))
		// no atom colors list has been set up, just check the color var
		if (!islist(color))
			return LOWER_TEXT(color) == looking_for_color
		if (!islist(looking_for_color))
			return FALSE
		return compare_list(color, looking_for_color)

	for(var/i in min_priority_index to max_priority_index)
		if (!atom_colors[i])
			continue

		if (!islist(looking_for_color))
			if (islist(atom_colors[i][ATOM_COLOR_VALUE_INDEX]))
				continue

			if (LOWER_TEXT(atom_colors[i][ATOM_COLOR_VALUE_INDEX]) == looking_for_color)
				return TRUE

			continue

		var/compared_matrix = atom_colors[i][ATOM_COLOR_VALUE_INDEX]
		if (atom_colors[i][ATOM_COLOR_TYPE_INDEX] == ATOM_COLOR_TYPE_FILTER)
			compared_matrix = atom_colors[i][ATOM_COLOR_VALUE_INDEX]["color"]

		if (compare_list(looking_for_color, compared_matrix))
			return TRUE

	return FALSE

///Resets the atom's color to null, and then sets it to the highest priority color available
/atom/proc/update_atom_color()
	var/old_filter = cached_color_filter
	var/old_color = color
	color = null
	cached_color_filter = null
	remove_filter(ATOM_PRIORITY_COLOR_FILTER)
	REMOVE_KEEP_TOGETHER(src, ATOM_COLOR_TRAIT)

	if (!atom_colors)
		if (!(SEND_SIGNAL(src, COMSIG_ATOM_COLOR_UPDATED, old_color || old_filter) & COMPONENT_CANCEL_COLOR_APPEARANCE_UPDATE) && old_filter)
			update_icon()
		return

	for (var/list/checked_color in atom_colors)
		if (checked_color[ATOM_COLOR_TYPE_INDEX] == ATOM_COLOR_TYPE_FILTER)
			add_filter(ATOM_PRIORITY_COLOR_FILTER, ATOM_PRIORITY_COLOR_FILTER_PRIORITY, checked_color[ATOM_COLOR_VALUE_INDEX])
			cached_color_filter = checked_color[ATOM_COLOR_VALUE_INDEX]
			break

		if (length(checked_color[ATOM_COLOR_VALUE_INDEX]))
			color = checked_color[ATOM_COLOR_VALUE_INDEX]
			break

	ADD_KEEP_TOGETHER(src, ATOM_COLOR_TRAIT)
	if (!(SEND_SIGNAL(src, COMSIG_ATOM_COLOR_UPDATED, old_color != color || old_filter != cached_color_filter) & COMPONENT_CANCEL_COLOR_APPEARANCE_UPDATE) && cached_color_filter != old_filter)
		update_icon()

/// Same as update_atom_color, but simplifies overlay coloring
/atom/proc/color_atom_overlay(mutable_appearance/overlay)
	overlay.color = color
	if (!cached_color_filter)
		return overlay
	// Apply the atom's color filter to the overlay using named filters so that
	// later calls to add_filter/update_filters (e.g., height displacement filters)
	// do not wipe out our coloration. Mirror prior behavior by propagating to
	// child overlays unless KEEP_TOGETHER is present.
	overlay.add_filter(ATOM_PRIORITY_COLOR_FILTER, ATOM_PRIORITY_COLOR_FILTER_PRIORITY, cached_color_filter)

	if(!(overlay.appearance_flags & KEEP_TOGETHER))
		// Recursively ensure any nested overlays/underlays also get the color filter
		for(var/mutable_appearance/child_overlay as anything in overlay.overlays)
			if(!(child_overlay.appearance_flags & KEEP_APART))
				color_atom_overlay(child_overlay)
		for(var/mutable_appearance/child_underlay as anything in overlay.underlays)
			if(!(child_underlay.appearance_flags & KEEP_APART))
				color_atom_overlay(child_underlay)

	return overlay
