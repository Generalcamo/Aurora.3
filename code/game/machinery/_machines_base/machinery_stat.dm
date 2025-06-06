/// Bitflag. Machine's base status. Can include `MACHINE_STAT_BROKEN`, `MACHINE_STAT_NOPOWER`, etc.
/obj/machinery/var/stat = NONE

/// Bitflag. The machine will never set stat to these flags.
/obj/machinery/var/stat_immune = MACHINE_STAT_NOSCREEN | MACHINE_STAT_NOINPUT
/**
 * Allows setting or unsetting a stat flag.
 *
 * **Parameters**:
 * - `statflag` (bitfield - One of `MACHINE_STAT_*`) - The stat flag to set.
 * - `new_state` (boolean) - The new state of the flag - 'On' or 'Off'.
 *
 * Returns boolean - Whether or not the stat was updated.
 */
/obj/machinery/proc/set_stat(statflag, new_state)
	if (stat_immune & statflag)
		return FALSE
	if (!new_state != !(stat & statflag))
		stat ^= statflag
		return TRUE
	return FALSE

/**
 * Updates the machine's stat immunity. This also updates the stat flag itself, if it's set and you're turning on immunity.
 *
 * **Parameters**:
 * - `statflag` (bitfield, One of `MACHINE_STAT_*`) - The stat flag to set immunity of.
 * - `new_state` (boolean, default `TRUE`) - The new state of the stat immunity flag.
 *
 * Returns boolean. Whether or not `stat` was updated during the operation.
 */
/obj/machinery/proc/set_stat_immunity(statflag, new_state = TRUE)
	if (new_state == !!(stat_immune & statflag))
		return FALSE
	if (new_state)
		(stat_immune |= statflag)
		if (stat & statflag)
			stat &= ~statflag
			return TRUE
		return FALSE
	stat_immune &= ~statflag
	return FALSE

/**
 * Toggles a stat flag.
 *
 * **Parameters**:
 * - `statflag` (bitfield - One of `MACHINE_STAT_*`) - The stat flag to toggle.
 *
 * Returns boolean or null. Null if the machine is immune to the state, otherwise, boolean based on the new state of the flag.
 */
/obj/machinery/proc/toggle_stat(statflag)
	if (stat_immune & statflag)
		return
	stat ^= statflag
	return !!(stat & statflag)

/**
 * Whether or not the machine is considered 'powered'. By default this translates directly to `!stat_check(MACHINE_STAT_NOPOWER)`, though the provided `additional_flags` will also be respected.
 *
 * Returns `FALSE` if any of the flags match.
 */
/obj/machinery/proc/is_powered(additional_flags = NONE)
	return !(stat & MACHINE_STAT_NOPOWER | additional_flags)

/**
 * Check to see if the machine is operable
 *
 * * `additional_flags` - Additional flags to check for, that could have been added to the `stat` variable
 *
 * Returns `TRUE` if the machine is operable, `FALSE` otherwise
 */
/obj/machinery/proc/operable(additional_flags = NONE)
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_BE_PURE(TRUE)

	if(stat & (MACHINE_STAT_NOPOWER|MACHINE_STAT_BROKEN|additional_flags))
		return FALSE
	else
		return TRUE

/// Inverse of `operable()`.
/obj/machinery/proc/inoperable(additional_flags = NONE)
	return !operable(additional_flags)

/**
 * Check to see if the machine is broken
 *
 * * `additional_flags` - Additional flags to check for, that could have been added to the `stat` variable
 *
 * Returns `TRUE` if the machine is broken, `FALSE` otherwise
 */
/obj/machinery/proc/is_broken(additional_flags = NONE)
	return !(stat & MACHINE_STAT_BROKEN | MACHINE_STAT_EMPED | additional_flags)

/**
 * Sets the machine's broken state. Currently a clone of `/obj/machinery/proc/toggle_stat` but for MACHINE_STAT_BROKEN specifically. Will in the future be used to set why the machine is broken
 *
 * **Parameters**:
 * - `new_state` (boolean) - The new state of the flag - 'TRUE' or 'FALSE'.
 *
 * Returns boolean - Whether or not the state was changed.
 */
/obj/machinery/proc/set_broken(new_state)
	if(new_state && (stat & MACHINE_STAT_BROKEN))
		return FALSE
	else if ((!new_state) && (stat & ~MACHINE_STAT_BROKEN))
		return FALSE
	toggle_stat(MACHINE_STAT_BROKEN)
	return TRUE
