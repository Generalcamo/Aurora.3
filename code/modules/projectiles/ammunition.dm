/obj/item/ammo_casing
	name = "bullet casing"
	desc = "A bullet casing."
	icon = 'icons/obj/ammo.dmi'
	icon_state = "s-casing"
	randpixel = 10
	flags = CONDUCT
	slot_flags = SLOT_BELT | SLOT_EARS
	throwforce = 1
	w_class = ITEMSIZE_TINY

	var/leaves_residue = 1
	var/caliber = ""					//Which kind of guns it can be loaded into
	var/max_stack = 5					// how many of us can fit in a pile
	var/projectile_type					//The bullet type to create when New() is called
	var/obj/item/projectile/BB = null	//The loaded bullet - make it so that the projectiles are created only when needed?
	var/spent_icon = "s-casing-spent"

	drop_sound = /singleton/sound_category/casing_drop_sound
	pickup_sound = 'sound/items/pickup/ring.ogg'
	var/reload_sound = 'sound/weapons/reload_bullet.ogg' //sound that plays when inserted into gun.

/obj/item/ammo_casing/Initialize()
	. = ..()
	if(ispath(projectile_type))
		BB = new projectile_type(src)
	else
		expend() // allows spawning spent casings by nulling projectile_type
	randpixel_xy()
	transform = turn(transform,rand(0,360))

/obj/item/ammo_casing/Destroy()
	QDEL_NULL(BB)
	. = ..()

//removes the projectile from the ammo casing
/obj/item/ammo_casing/proc/expend()
	. = BB
	BB = null
	set_dir(pick(alldirs)) //spin spent casings
	update_icon()

/obj/item/ammo_casing/attackby(obj/item/W as obj, mob/user as mob)
	if(W.isscrewdriver())
		if(!BB)
			to_chat(user, "<span class='notice'>There is no bullet in the casing to inscribe anything into.</span>")
			return

		var/tmp_label = ""
		var/label_text = sanitizeSafe(input(user, "Inscribe some text into \the [initial(BB.name)]","Inscription",tmp_label), MAX_NAME_LEN)
		if(length(label_text) > 20)
			to_chat(user, "<span class='warning'>The inscription can be at most 20 characters long.</span>")
		else if(!label_text)
			to_chat(user, "<span class='notice'>You scratch the inscription off of [initial(BB)].</span>")
			BB.name = initial(BB.name)
		else
			to_chat(user, "<span class='notice'>You inscribe \"[label_text]\" into \the [initial(BB.name)].</span>")
			BB.name = "[initial(BB.name)] (\"[label_text]\")"
	else if(istype(W, /obj/item/ammo_casing))
		if(W.type != src.type)
			to_chat(user, SPAN_WARNING("Ammo of different types cannot stack!"))
			return
		if(max_stack == 1)
			to_chat(user, SPAN_WARNING("\The [src] cannot be stacked!"))
			return
		if(!src.BB)
			to_chat(user, SPAN_WARNING("That round is spent!"))
			return
		var/obj/item/ammo_casing/B = W
		if(!B.BB)
			to_chat(user, SPAN_WARNING("Your round is spent!"))
			return
		var/obj/item/ammo_pile/pile = new /obj/item/ammo_pile(get_turf(user), list(src, W))
		user.put_in_hands(pile)
	..()

/obj/item/ammo_casing/update_icon()
	if(spent_icon && !BB)
		icon_state = spent_icon

/obj/item/ammo_casing/examine(mob/user)
	. = ..()
	if (!BB)
		to_chat(user, "This one is spent.")
