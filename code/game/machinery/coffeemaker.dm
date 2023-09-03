/obj/machinery/coffeemaker
	name = "\improper Getmore! InstaCoffee maker"
	desc = "A Getmore! product, designed to take pre-packaged coffee grounds and turn it into a fresh, hot drink."
	idle_power_usage = 100
	active_power_usage = 1500
	manufacturer = "getmore"

	var/obj/item/reagent_containers/food/drinks/drinkingglass/newglass/coffeepot/coffeepot = null
	var/brewing = FALSE
	var/brew_time = 20 SECONDS
	var/speed = 1
	///The cartridge to make coffee from.
	var/obj/item/coffee_cartridge/cartridge = null
	var/coffee_cups = 15
	var/max_coffee_cups = 15
	var/sugar_packs = 10
	var/max_sugar_packs = 10
	var/sweetener_packs = 10
	var/max_sweetener_packs = 10
	var/creamer_packs = 10
	var/max_creamer_packs = 10

	var/static/radial_examine = image(icon = 'icons/hud/radial.dmi', icon_state = "radial_examine")
	var/static/radial_brew = image(icon = 'icons/hud/radial_coffee.dmi', icon_state = "radial_brew")
	var/static/radial_eject_pot = image(icon = 'icons/hud/radial_coffee.dmi', icon_state = "radial_eject_pot")
	var/static/radial_eject_cartridge = image(icon = 'icons/hud/radial_coffee.dmi', icon_state = "radial_eject_cartridge")
	var/static/radial_take_cup = image(icon = 'icons/hud/radial_coffee.dmi', icon_state = "radial_take_cup")
	var/static/radial_take_sugar = image(icon = 'icons/hud/radial_coffee.dmi', icon_state = "radial_take_sugar")
	var/static/radial_take_sweetener = image(icon = 'icons/hud/radial_coffee.dmi', icon_state = "radial_take_sweetener")
	var/static/radial_take_creamer = image(icon = 'icons/hud/radial_coffee.dmi', icon_state = "radial_take_creamer")

/obj/machinery/coffeemaker/Initialize(mapload)
	. = ..()
	if(mapload)
		coffeepot = new /obj/item/reagent_containers/cup/coffeepot(src)
		cartridge = new /obj/item/coffee_catridge/basic(src)

/obj/machinery/coffeemaker/Destroy()
	QDEL_NULL(coffeepot)
	QDEL_NULL(cartridge)
	return ..()

/obj/machinery/coffeemaker/update_icon()
	cut_overlays()
	if (coffeepot)
		add_overlay("coffeemaker_pot")
	if (cartridge)
		add_overlay("coffeemaker_cartridge")

/obj/machinery/coffeemaker/proc/replace_pot(mob/living/user, /obj/item/reagent_containers/food/drinks/drinkingglass/newglass/coffeepot/new_coffeepot)
	if(!user)
		return FALSE
	if(new_coffeepot)
		coffeepot = new_coffeepot
	balloon_alert_to_viewers(user, "replaced pot")
	update_icon()
	return TRUE

/obj/machinery/coffeemaker/proc/replace_cartridge(mob/living/user, obj/item/coffee_cartridge/new_cartridge)
	if(!user)
		return FALSE
	if(cartridge)
		try_put_in_hand(cartridge, user)
	if(new_cartridge)
		cartridge = new_cartridge
	balloon_alert_to_viewers(user, "replaced cartridge")
	update_icon()
	return TRUE

/obj/machinery/coffeemaker/attackby(obj/item/attack_item, mob/user)
	//You can only screw open empty grinder
	if(!coffeepot && default_deconstruction_screwdriver(user, icon_state, icon_state, attack_item))
		return FALSE

	if(default_deconstruction_crowbar(attack_item))
		return

	//Can't insert coffee if the panel's open!
	if(panel_open)
		return TRUE

	if(istype(attack_item, /obj/item/reagent_containers/food/drinks/drinkingglass/newglass/coffeepot) && attack_item.is_open_container())
		var/obj/item/reagent_containers/food/drinks/drinkingglass/newglass/coffeepot/new_pot = attack_item
		//if(user.transfer)
		replacePot(user, new_pot)
		return TRUE

/obj/machinery/coffeemaker/proc/try_brew()
	if(!cartridge)
		balloon_alert(user, "no coffee cartridge inserted!")
		return FALSE
	if(cartridge.charges < 1)
		balloon_alert(user, "coffee cartridge empty!")
	if(!coffeepot)
		balloon_alert(usr, "no coffeepot inside!")
		return FALSE
	if(stat & (NOPOWER|BROKEN))
		balloon_alert(usr, "machine unpowered!")
		return FALSE
	if(coffeepot.reagents.total_volume >= coffeepot.reagents.maximum_volume)
		balloon_alert(usr, "the coffeepot is already full!")
		return FALSE
	return TRUE

/obj/machinery/coffeemaker/ui_interact(mob/user)
	. = ..()

	var/list/options = list()

	if(coffeepot)
		options["Eject Pot"] = radial_eject_pot

	if(cartridge)
		options["Eject Cartridge"] = radial_eject_cartridge

	options["Brew"] = radial_brew //brew is always available as an option, when the machine is unable to brew the player is told by balloon alerts whats exactly wrong

	if(coffee_cups > 0)
		options["Take Cup"] = radial_take_cup

	if(sugar_packs > 0)
		options["Take Sugar"] = radial_take_sugar

	if(sweetener_packs > 0)
		options["Take Sweetener"] = radial_take_sweetener

	if(creamer_packs > 0)
		options["Take Creamer"] = radial_take_creamer

	if(isAI(user))
		if(stat & NOPOWER)
			return
		options["Examine"] = radial_examine

	var/choice

	if(length(options) < 1)
		return
	if(length(options) == 1)
		choice = options[1]
	else
		choice = show_radial_menu(user, src, options, require_near = !issilicon(user))

	// post choice verification
	if(brewing || (isAI(user) && stat & NOPOWER) || use_check(user))
		return

	switch(choice)
		if("Brew")
			brew(user)
		if("Eject Pot")
			eject_pot(user)
		if("Eject Cartridge")
			eject_cartridge(user)
		if("Examine")
			examine(user)
		if("Take Cup")
			take_cup(user)
		if("Take Sugar")
			take_sugar(user)
		if("Take Sweetener")
			take_sweetener(user)
		if("Take Creamer")
			take_creamer(user)

/obj/machinery/coffeemaker/proc/eject_pot(mob/user)
	if(coffeepot)
		replace_pot(user)

/obj/machinery/coffeemaker/proc/eject_cartridge(mob/user)
	if(cartridge)
		replace_cartridge(user)

/obj/machinery/coffeemaker/proc/take_cup(mob/user)
	if(!coffee_cups) //shouldn't happen, but we all know how stuff manages to break
		balloon_alert(user, "no cups left!")
		return
	var/obj/item/reagent_containers/food/drinks/takeaway_cup_idris/new_cup = new(get_turf(src)) //Yes it's a getmore machine. Let's call it a cross-company deal
	user.put_in_hands(new_cup)
	coffee_cups--
	update_icon()

/obj/machinery/coffeemaker/proc/take_sugar(mob/user)
	if(!sugar_packs)
		balloon_alert(user, "no sugar left!")
		return
	var/obj/item/reagent_containers/food/condiment/small/packet/sugar/new_pack = new(get_turf(src))
	user.put_in_hands(new_pack)
	sugar_packs--
	update_icon()

/obj/machinery/coffeemaker/proc/take_sweetener(mob/user)
	if(!sweetener_packs)
		balloon_alert(user, "no sweetener left!")
		return
	var/obj/item/reagent_containers/food/condiment/small/packet/sweetener/new_pack = new(get_turf(src))
	user.put_in_hands(new_pack)
	sweetener_packs--
	update_icon()

/obj/machinery/coffeemaker/proc/take_creamer(mob/user)
	if(!creamer_packs)
		balloon_alert(user, "no creamer left!")
		return
	var/obj/item/reagent_containers/food/condiment/small/packet/creamer/new_pack = new(get_turf(src))
	user.put_in_hands(new_pack)
	creamer_packs--
	update_icon()

/obj/machinery/coffeemaker/proc/operate_for(time, silent = FALSE)
	brewing = TRUE
//	if(!silent)
//		playsound(src, 'sound/machines/coffeemaker_brew.ogg', 20, vary = TRUE)
//	toggle_steam()
	update_use_power(POWER_USE_ACTIVE)
	addtimer(CALLBACK(src, PROC_REF(stop_operating)), time / speed)

/obj/machinery/coffeemaker/proc/stop_operating()
	brewing = FALSE
	update_use_power(POWER_USE_IDLE)
	toggle_steam()

/obj/machinery/coffeemaker/proc/brew()
	if(!try_brew())
		return
	operate_for(brew_time)
	coffeepot.reagents.add_reagent_list(cartridge.drink_type)
	cartridge.charges--

//Coffee Cartridges: like toner, but for your coffee!
//No you can't refill these. This is the corporate future, there's DRM in these!
/obj/item/coffee_cartridge
	abstract_type = /obj/item/coffee_cartridge
	icon = 'icons/obj/food/cartridges.dmi'
	var/charges = 6
	var/list/drink_type = list(/singleton/reagent/drink/coffee = 120)

/obj/item/coffee_cartridge/examine(mob/user)
	if(charges)
		to_chat(user, SPAN_NOTICE("The cartridge has [charges] portions of grounds remaining."))
	else
		to_chat(user, SPAN_WARNING("The cartridge has no unspent grounds remaining."))

/obj/item/coffee_cartridge/basic
	name = "coffeemaker cartridge- Caffè Generico"
	desc = "A coffee cartridge manufactured by Chip's Coffee Roasters, for use with the Getmore! InstaCoffee system."
	icon_state = "cartridge_basic"

/obj/item/coffee_cartridge/fancy
	name = "coffeemaker cartridge - Caffè Fantasioso"
	desc = "A fancy coffee cartridge manufactured by Chip's Coffee Roasters, for use with the Getmore! InstaCoffee system."
	icon_state = "cartridge_blend"

//Here's the joke before I get 50 issue reports: they're all the same, and that's intentional
/obj/item/coffee_cartridge/fancy/Initialize(mapload)
	. = ..()
	var/coffee_type = pick("blend", "blue_mountain", "kilimanjaro", "mocha")
	switch(coffee_type)
		if("blend")
			name = "coffeemaker cartridge - Miscela di Piccione"
			icon_state = "cartridge_blend"
		if("blue_mountain")
			name = "coffeemaker cartridge - Montagna Blu"
			icon_state = "cartridge_blue_mtn"
		if("kilimanjaro")
			name = "coffeemaker cartridge - Kilimangiaro"
			icon_state = "cartridge_kilimanjaro"
		if("mocha")
			name = "coffeemaker cartridge - Moka Arabica"
			icon_state = "cartridge_mocha"

/obj/item/coffee_cartridge/decaf
	name = "coffeemaker cartridge - Caffè Decaffeinato"
	desc = "A decaf coffee cartridge manufactured by Chip's Coffee Roasters, for use with the Getmore! InstaCoffee system."
	icon_state = "cartridge_decaf"

/obj/item/coffee_cartridge/hotcocoa
	name = "coffeemaker cartridge - Cocoa Grande"
	desc = "A hot chocolate cartridge manufactured by Chip's Coffee Roasters, for use with the Getmore! InstaCoffee system."
	icon_state = "cartridge_hotcocoa"
	drink_type = list(/singleton/reagent/drink/hot_coco = 120)

/obj/item/coffee_cartridge/espresso
	name = "coffeemaker cartridge - Caffè Espresso"
	desc = "An espresso cartridge manufactured by Chip's Coffee Roasters, for use with the Getmore! InstaCoffee system."
	icon_state = "cartridge_espresso"
	drink_type = list(/singleton/reagent/drink/coffee/espresso = 120)

