/datum/progressbar
	///The progress bar visual element
	var/image/progress/bar/bar
	///The progress bar frame visual element
	var/image/progress/frame/frame
	///The progress bar background visual element
	var/image/progress/bg/bg
	///The progress bar tag, used to set the visual
	var/bar_tag = PROG_BAR_GENERIC
	var/bg_tag = PROG_BG_GENERIC
	var/frame_tag = PROG_FRAME_GENERIC
	///The target where this target bar is applied and where it is shown
	var/atom/bar_loc
	///The mob whose client sees the progress bar
	var/mob/user
	///The client seeing the progress bar
	var/client/user_client
	///Effectively the number of steps the progress bar will need before reaching completion
	var/goal = 1
	///Control check to see if the progress was interrupted before reaching its goal
	var/last_progress = 0
	///Variable to ensure smooth visual stacking on multiple progress bars
	var/listindex = 0
	///The type of our last value for bar_loc, for debugging
	var/location_type
	///Whether to immediately destroy a progress bar when full, rather than wait for an animation
	var/destroy_on_full = FALSE
//	var/user_prog_display_tag = BUSY_ICON_GENERIC
//	var/target_prog_display_tag = BUSY_ICON_GENERIC
	var/list/prog_displays

/datum/progressbar/New(mob/User, goal_number, atom/target, do_public_progress)
	. = ..()
	if(!istype(target))
		stack_trace("Invalid target '[target]' passed in /datum/progressbar")
		qdel(src)
		return
	if(QDELETED(User) || !istype(User))
		stack_trace("[isnull(User) ? "Null" : "Invalid"] user passed in /datum/progressbar")
		qdel(src)
		return
	if(!bar_tag)
		stack_trace("Invalid bar tag '[bar_tag]' passed in /datum/progressbar")
		qdel(src)
		return
	if(goal_number)
		goal = goal_number
	bar = new bar_tag
	bar_loc = target
	location_type = bar_loc.type
	bar.loc = bar_loc
	user = User

	if(frame_tag)
		frame = new frame_tag
		bar.overlays += frame_tag

	if(bg_tag)
		bg = new bg_tag
		bar.underlays += bg_tag

	LAZYADDASSOCLIST(user.progressbars, bar_loc, src)
	var/list/bars = user.progressbars[bar_loc]
	listindex = bars.len

//	if(do_public_progress)
//		var/datum/progressicon/U = new(user, user_prog_display_tag)
//		LAZYADD(prog_displays, U)
//		if(target != user)
//			var/datum/progressicon/T = new(target, target_prog_display_tag)
//			LAZYADD(prog_displays, T)


	if(user)
		user_client = user.client
		addProgBarImageToClient()

	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(onUserDelete))
	RegisterSignal(user, COMSIG_MOB_LOGOUT, PROC_REF(cleanUserClient))
	RegisterSignal(user, COMSIG_MOB_LOGIN, PROC_REF(onUserLogin))

///Updates the progress bar image visually.
/datum/progressbar/proc/update(progress)
	progress = clamp(progress, 0, goal)
	if(progress == last_progress)
		return
	last_progress = progress
	bar.update_icon(progress, goal)
	if(destroy_on_full && progress == goal)
		QDEL_IN(src, 5)

///Called on progress end, be it successful or a failure. Wraps up things to delete the datum and bar.
/datum/progressbar/proc/endProgress()
	if(last_progress != goal)
		bar.icon_state = "[initial(bar.icon_state)]_fail"

	animate(bar, alpha = 0, time = PROGRESSBAR_ANIMATION_TIME)

	QDEL_IN(src, PROGRESSBAR_ANIMATION_TIME)


/datum/progressbar/Destroy()
	if(user)
		for(var/pb in user.progressbars[bar_loc])
			var/datum/progressbar/progress_bar = pb
			if(progress_bar == src || progress_bar.listindex <= listindex)
				continue
			--listindex
			var/current_bar_height = bar.height
			bar.pixel_y = 32 + (current_bar_height * (listindex - 1))
			var/dist_to_travel = 32 + (current_bar_height * (listindex - 1)) - current_bar_height
			animate(bar, pixel_y = dist_to_travel, time = PROGRESSBAR_ANIMATION_TIME, easing = SINE_EASING)

		LAZYREMOVEASSOC(user.progressbars, bar_loc, src)
		user = null
	if(user_client)
		cleanUserClient()

	bar_loc = null

	if(bar)
		QDEL_NULL(bar)

	return ..()

///Adds a smoothly-appearing progress bar image to the player's screen.
/datum/progressbar/proc/addProgBarImageToClient()
	user_client.images += bar
	animate(bar, pixel_y = 32 + (bar.height * (listindex - 1)), alpha = 255, time = PROGRESSBAR_ANIMATION_TIME, easing = SINE_EASING)

///Called right before the user's Destroy()
/datum/progressbar/proc/onUserDelete(datum/source)
	SIGNAL_HANDLER

	user.progressbars = null //We can simply nuke the list and stop worrying about updating other prog bars if the user itself is gone.
	user = null
	qdel(src)

///Removes the progress bar from the user_client and nulls the variables if it exists
/datum/progressbar/proc/cleanUserClient(datum/source)
	SIGNAL_HANDLER

	if(!user_client) //Disconnected, already gone
		return
	user_client.images -= bar
	user_client = null

///Called by user's Login(), it transfers the progress bar image to the new client.
/datum/progressbar/proc/onUserLogin(datum/source)
	SIGNAL_HANDLER

	// Sanity checking to ensure client is mob and that the client did not log off again
	if(user_client)
		if(user_client == user.client)
			return
		cleanUserClient()
	if(!user.client)
		return

	user_client = user.client
	addProgBarImageToClient()

/datum/progressbar/autocomplete
	destroy_on_full = TRUE

/image/progress
	icon = 'icons/effects/progressbar.dmi'
	layer = 21 //TODO: Move this to a proper plane and layer when that PR is finished
	appearance_flags = RESET_COLOR|RESET_TRANSFORM|NO_CLIENT_COLOR|RESET_ALPHA|PIXEL_SCALE

/image/progress/bar
	icon_state = "prog_bar_1"
	alpha = 0
	var/interval = 5
	var/height = PROGRESSBAR_STANDARD_HEIGHT

/image/progress/bar/proc/update_icon(progress, goal)
	icon_state = "[initial(icon_state)]_[round(((progress / goal) * 100), interval)]"

/image/progress/bg
	icon_state = "prog_bar_1_bg"
	appearance_flags = RESET_COLOR|RESET_TRANSFORM|NO_CLIENT_COLOR|PIXEL_SCALE

/image/progress/frame
	icon_state = "prog_bar_1_frame"
	appearance_flags = RESET_COLOR|RESET_TRANSFORM|NO_CLIENT_COLOR|PIXEL_SCALE

/datum/progressbar/battery
	bar_tag = PROG_BAR_BATTERY
	frame_tag = PROG_FRAME_BATTERY

/image/progress/bar/battery
	icon_state = "prog_bar_2"
	interval = 10

/image/progress/frame/battery
	icon_state = "prog_bar_2_frame"

/datum/progressbar/clock
	bar_tag = PROG_BAR_CLOCK
	frame_tag = PROG_FRAME_CLOCK
	bg_tag = PROG_BG_CLOCK

/image/progress/bar/clock
	icon_state = "prog_bar_5"
	interval = 4
	height = 12

/image/progress/frame/clock
	icon_state = "prog_bar_5_frame"

/image/progress/bg/clock
	icon_state = "prog_bar_2_bg"

/image/progress/bar/clock/mono
	icon_state = "prog_bar_4"

/datum/progressicon
	var/image/progdisplay/display
	var/image/progdisplay/display_tag
	var/atom/target
