///Atom that manages and controls multiple planes. It's an atom so we can hook into add_filter etc. Multiple controllers can control one plane.
///Of note: plane master controllers are currently not very extensively used, because render plates fill a semi similar niche
///This could well change someday, and I'd like to keep this stuff around, so we use it for a few cases just out of convenience
/atom/movable/plane_master_controller
	///List of planes in this controllers control. Initially this is a normal list, but becomes an assoc list of plane numbers as strings | plane instance
	var/list/controlled_planes = list()
	///hud that owns this controller
	var/datum/hud/owner_hud

INITIALIZE_IMMEDIATE(/atom/movable/plane_master_controller)

///Ensures that all the planes are correctly in the controlled_planes list.
/atom/movable/plane_master_controller/Initialize(mapload, datum/hud/hud)
	. = ..()
	if(!istype(hud))
		return

	owner_hud = hud

/atom/movable/plane_master_controller/proc/get_planes()
	var/returned_planes = list()
	for(var/true_plane in controlled_planes)
		returned_planes += get_true_plane(true_plane)
	return returned_planes

/atom/movable/plane_master_controller/proc/get_true_plane(true_plane)
	var/list/returned_planes = owner_hud.get_true_plane_masters(true_plane)
	if(!length(returned_planes)) //If we looked for a hud that isn't instanced, just keep going
		stack_trace("[plane] isn't a valid plane master layer for [owner_hud.type], are you sure it exists in the first place?")
		return

	return returned_planes

///Full override so we can just use filterrific
/atom/movable/plane_master_controller/add_filter(name, priority, list/params)
	. = ..()
	for(var/atom/movable/screen/plane_master/pm_iterator as anything in get_planes())
		pm_iterator.add_filter(name, priority, params)

///Full override so we can just use filterrific
/atom/movable/plane_master_controller/remove_filter(name_or_names, update = TRUE)
	. = ..()
	for(var/atom/movable/screen/plane_master/pm_iterator as anything in get_planes())
		pm_iterator.remove_filter(name_or_names, update)

/atom/movable/plane_master_controller/update_filters(start_index = null)
	. = ..()
	for(var/atom/movable/screen/plane_master/pm_iterator as anything in get_planes())
		pm_iterator.update_filters(start_index)

///Gets all filters for this controllers plane masters
/atom/movable/plane_master_controller/proc/get_filters(name)
	. = list()
	for(var/atom/movable/screen/plane_master/pm_iterator as anything in get_planes())
		. += pm_iterator.get_filter(name)

///Transitions all filters owned by this plane master controller
/atom/movable/plane_master_controller/transition_filter(name, time, list/new_params, easing, loop)
	. = ..()
	for(var/atom/movable/screen/plane_master/pm_iterator as anything in get_planes())
		pm_iterator.transition_filter(name, new_params, time, easing, loop)

/atom/movable/plane_master_controller/game
	name = PLANE_MASTERS_GAME
	controlled_planes = list(
		SPACE_PLANE,
		SKYBOX_PLANE,
		GAME_PLANE,
		LIGHTING_PLANE
	)

/// Exists for convienience when referencing all non-master render plates.
/// This is the whole game and the UI, but not the escape menu.
/atom/movable/plane_master_controller/non_master
	name = PLANE_MASTERS_NON_MASTER
	controlled_planes = list(
		RENDER_PLANE_GAME,
		RENDER_PLANE_NON_GAME,
	)
