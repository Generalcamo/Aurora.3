//Gun loading types
#define SINGLE_CASING 	1	//The gun only accepts ammo_casings. ammo_magazines should never have this as their mag_type.
#define SPEEDLOADER 	2	//Transfers casings from the mag to the gun when used.
#define MAGAZINE 		4	//The magazine item itself goes inside the gun

//An item that holds casings and can be used to put them inside guns
/obj/item/ammo_magazine
	name = "magazine"
	desc = "A magazine for some kind of gun."
	icon_state = "357"
	icon = 'icons/obj/ammo.dmi'
	flags = CONDUCT
	slot_flags = SLOT_BELT
	item_state = "box"
	matter = list(DEFAULT_WALL_MATERIAL = 500)
	throwforce = 5
	w_class = ITEMSIZE_SMALL
	throw_speed = 4
	throw_range = 10

	var/list/stored_ammo = list()
	var/caliber = "357"
	var/max_ammo = 7

	///Wording used for individual units of ammo, e.g. cartridges (for regular ammo), shells (for shotgun shells)
	var/casing_phrasing = "cartridge"

	var/ammo_type = /obj/item/ammo_casing //ammo type that is initially loaded
	var/start_empty = FALSE

	var/magazine_flags = MAGAZINE_REFILLABLE

	var/multiple_sprites = 0
	//because BYOND doesn't support numbers as keys in associative lists
	var/list/icon_keys = list()		//keys
	var/list/ammo_states = list()	//values

	var/insert_sound = /singleton/sound_category/metal_slide_reload //sound it plays when it gets inserted into a gun.
	var/eject_sound = 'sound/weapons/magazine_eject.ogg'

	///Sound that plays when a bullet is inserted into the magazine
	var/bullet_insert_sound = 'sound/weapons/reload_bullet.ogg'

	/// If this and ammo_band_icon aren't null, run update_ammo_band(). Is the color of the band, such as black on the Xanan shotgun's AP bullets
	var/ammo_band_color
	/// If this and ammo_band_color aren't null, run update_ammo_band() Is the greyscale icon used for the ammo band.
	var/ammo_band_icon
	/// Is the greyscale icon used for the ammo band when it's empty of bullets, only if it's not null.
	var/ammo_band_icon_empty

/obj/item/ammo_magazine/Initialize()
	. = ..()
	if(multiple_sprites)
		initialize_magazine_icondata(src)

	if(!start_empty)
		top_off(starting = TRUE)
	update_icon()

/obj/item/ammo_magazine/Destroy()
	QDEL_NULL_LIST(stored_ammo)
	. = ..()

/**
 * top_off is used to refill the magazine to max, in case you want to increase the size of a magazine with VV then refill it at once
 *
 * Arguments:
 * * load_type - if you want to specify a specific ammo casing type to load, enter the path here, otherwise it'll use the basic [/obj/item/ammo_box/var/ammo_type]. Must be a compatible round
 * * starting - Relevant for revolver cylinders, if FALSE then we mind the nulls that represent the empty cylinders (since those nulls don't exist yet if we haven't initialized when this is TRUE)
 */
/obj/item/ammo_magazine/proc/top_off(load_type, starting=TRUE)
	if(!load_type)
		load_type = ammo_type

	var/obj/item/ammo_casing/round_check = load_type
	if(!starting && !(caliber ? (caliber == initial(round_check.caliber)) : (ammo_type == load_type)))
		stack_trace("Tried loading unsupported ammo casing type [load_type] into magazine [type].")

	for(var/i in max(1, stored_ammo.len) to max_ammo)
		stored_ammo += new round_check(src)
	update_icon()

///Puts a round into the magazine
/obj/item/ammo_magazine/proc/add_round(obj/item/ammo_casing/R, replace_spent = FALSE)
	if(!R || !(caliber == R.caliber))
		return FALSE

	if(stored_ammo.len < max_ammo)
		stored_ammo += R
		R.forceMove(src)
		return TRUE

	//For internal magazines, when full, start replacing spent ammo
	else if(replace_spent)
		for(var/obj/item/ammo_casing/AC in stored_ammo)
			if(!AC.BB)
				stored_ammo -= AC
				AC.forceMove(get_turf(src.loc))

				stored_ammo += R
				R.forceMove(src)
				return TRUE
	return FALSE

///gets a round from the magazine, if keep is TRUE the round will be moved to the bottom of the list.
/obj/item/ammo_magazine/proc/get_round(keep = FALSE)
	var/ammo_len = length(stored_ammo)
	if(!ammo_len)
		return null
	var/casing = stored_ammo[ammo_len]
	if(keep)
		stored_ammo -= casing
		stored_ammo.Insert(1,casing)
	return casing

/obj/item/ammo_magazine/attackby(obj/item/W, mob/user, replace_spent = FALSE)
	var/num_loaded = 0
	if(istype(W, /obj/item/ammo_casing))
		var/obj/item/ammo_casing/AC = W
		if(give_round(AC, replace_spent))
			W.forceMove(src)
			num_loaded++
			AC.update_icon()

	if(num_loaded)
		to_chat(user, SPAN_NOTICE("You load [num_loaded > 1 ? "[num_loaded] [W.name]s" : "a [W.name]"] into \the [src]!"))
		playsound(src, bullet_insert_sound, 60, TRUE)
		update_icon()

	return num_loaded

/obj/item/ammo_magazine/attack_self(mob/user)
	if(!stored_ammo.len)
		FEEDBACK_FAILURE(user, "\The [src] is already empty!")
		return
	to_chat(user, SPAN_NOTICE("You empty [src]."))
	for(var/obj/item/ammo_casing/C in stored_ammo)
		C.forceMove(user.loc)
		playsound(C, /singleton/sound_category/casing_drop_sound, 50, FALSE)
		C.set_dir(pick(alldirs))
	stored_ammo.Cut()
	update_icon()

/obj/item/ammo_magazine/update_icon()
	if(multiple_sprites)
		//find the lowest key greater than or equal to stored_ammo.len
		var/new_state = null
		for(var/idx in 1 to icon_keys.len)
			var/ammo_count = icon_keys[idx]
			if (ammo_count >= stored_ammo.len)
				new_state = ammo_states[idx]
				break
		icon_state = (new_state)? new_state : initial(icon_state)
	if(!length(stored_ammo))
		recyclable = TRUE
	else
		recyclable = FALSE

/obj/item/ammo_magazine/examine(mob/user)
	. = ..()
	to_chat(user, "There [(stored_ammo.len == 1)? "is" : "are"] [stored_ammo.len] round\s left!")

/obj/item/ammo_magazine/proc/ammo_count()
	var/bullets = 0
	for(var/obj/item/ammo_casing/bullet in stored_ammo)
		if(bullet)
			bullets++
	return bullets

/obj/item/ammo_magazine/proc/ammo_list()
	return stored_ammo.Copy()

//magazine icon state caching (caching lists are in SSicon_cache)

/proc/initialize_magazine_icondata(var/obj/item/ammo_magazine/M)
	var/list/magazine_icondata_keys = SSicon_cache.magazine_icondata_keys
	var/list/magazine_icondata_states = SSicon_cache.magazine_icondata_states

	var/typestr = "[M.type]"
	if(!(typestr in magazine_icondata_keys) || !(typestr in magazine_icondata_states))
		magazine_icondata_cache_add(M)

	M.icon_keys = magazine_icondata_keys[typestr]
	M.ammo_states = magazine_icondata_states[typestr]

/proc/magazine_icondata_cache_add(var/obj/item/ammo_magazine/M)
	var/list/magazine_icondata_keys = SSicon_cache.magazine_icondata_keys
	var/list/magazine_icondata_states = SSicon_cache.magazine_icondata_states

	var/list/icon_keys = list()
	var/list/ammo_states = list()
	var/list/states = icon_states(M.icon)
	for(var/i = 0, i <= M.max_ammo, i++)
		var/ammo_state = "[M.icon_state]-[i]"
		if(ammo_state in states)
			icon_keys += i
			ammo_states += ammo_state

	magazine_icondata_keys["[M.type]"] = icon_keys
	magazine_icondata_states["[M.type]"] = ammo_states
