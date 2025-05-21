///Amount of coffee beans that can fit inside the Idris coffeemaker
#define BEAN_CAPACITY 10
///Standard temperature of coffee made by the coffee machines. About 90° Celcius
#define STANDARD_COFFEE_TEMPERATURE 363.15

//Base type for all coffee makers.
ABSTRACT_TYPE(/obj/machinery/coffeemaker)
	name = "coffeemaker"
	desc = "A Modello 4 Coffeemaker that brews coffee and holds it at the perfect temperature of 90° Celcius. Made by Piccionaia Home Appliances, a known subsidiary of Getmore Corporation."
	icon = 'icons/obj/machinery/coffeemaker.dmi'
	icon_state = "coffeemaker_nopot_nocart"
	var/obj/item/reagent_containers/glass/beaker/pitcher/coffeepot = null
	var/brewing = FALSE
	var/brew_time = 20 SECONDS
	var/speed = 1

	// Generic coffee maker vars, determining storage of condiments and cups
	/// The number of cups left
	var/coffee_cups = 15
	var/max_coffee_cups = 15
	///The type of coffee cup to store, by default, in the coffee machine
	var/initial_cup = /obj/item/reagent_containers/food/drinks/takeaway_cup/nanotrasen
	/// The amount of sugar packets left
	var/sugar_packs = 10
	var/max_sugar_packs = 10
	/// The amount of sweetener packets left
	var/sweetener_packs = 10
	var/max_sweetener_packs = 10
	/// The amount of creamer packets left
	var/creamer_packs = 10
	var/max_creamer_packs = 10

	//Cartridge Coffee Vars
	/// The coffee cartridge to make coffee from. In the future, coffee grounds are like printer ink.
	var/obj/item/coffee_cartridge/cartridge = null
	/// The type path to instantiate for the coffee cartridge the device initially comes with, eg. /obj/item/coffee_cartridge
	var/initial_cartridge = null

	//Grinder Coffee Vars
	/// Current amount of coffee beans stored
	var/coffee_amount = 0
	///Maximum amount of coffee beans stored
	var/max_coffee_amount = 0
	/// List of coffee bean objects are stored
	var/list/coffee_beans = list()

	//STATIC UI VARIABLES
	var/static/radial_examine = image(icon = 'icons/mob/screen/radial.dmi', icon_state = "radial_examine")
	var/static/radial_brew = image(icon = 'icons/mob/screen/radial_coffee.dmi', icon_state = "radial_brew")
	var/static/radial_eject_pot = image(icon = 'icons/mob/screen/radial_coffee.dmi', icon_state = "radial_eject_pot")
	var/static/radial_eject_cartridge = image(icon = 'icons/mob/screen/radial_coffee.dmi', icon_state = "radial_eject_cartridge")
	var/static/radial_take_cup = image(icon = 'icons/mob/screen/radial_coffee.dmi', icon_state = "radial_take_cup")
	var/static/radial_take_sugar = image(icon = 'icons/mob/screen/radial_coffee.dmi', icon_state = "radial_take_sugar")
	var/static/radial_take_sweetener = image(icon = 'icons/mob/screen/radial_coffee.dmi', icon_state = "radial_take_sweetener")
	var/static/radial_take_creamer = image(icon = 'icons/mob/screen/radial_coffee.dmi', icon_state = "radial_take_creamer")

/obj/machinery/coffeemaker/Initialize(mapload)
	. = ..()
	if(mapload)
		coffeepot = new /obj/item/reagent_containers/glass/beaker/pitcher(src)
		if(initial_cartridge)
			cartridge = new initial_cartridge(src)

/obj/machinery/coffeemaker/Destroy()
	QDEL_NULL(coffeepot)
	QDEL_NULL(cartridge)
	QDEL_LIST(coffee_beans)
	return ..()

/obj/machinery/coffeemaker/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == coffeepot)
		coffeepot = null
		update_icon()
	if(gone == cartridge)
		cartridge = null
		update_icon()
	if(gone in coffee_beans)
		coffee_beans -= gone
		update_icon()

/obj/machinery/coffeemaker/update_icon()
	. = ..()
	ClearOverlays()
	var/list/overlays = overlay_checks()
	AddOverlays(overlays)

/obj/machinery/coffeemaker/proc/overlay_checks()
	. = list()
	if(coffeepot)
		if(istype(coffeepot, /obj/item/reagent_containers/glass/beaker/pitcher/bluespace))
			. += "coffeemaker_pot_bluespace"
		else
			. += "coffeemaker_pot_[coffeepot.reagents.total_volume ? "full" : "empty"]"
	if(cartridge)
		. += "coffeemaker_cartridge"
	return .

/obj/machinery/coffeemaker/proc/replace_pot(mob/living/user, obj/item/reagent_containers/glass/beaker/pitcher/new_coffeepot)
	if(!user)
		return FALSE
	if(coffeepot)
		user.put_in_hands(coffeepot)
	if(new_coffeepot)
		coffeepot = new_coffeepot
		balloon_alert(user, "replaced pot")
	update_icon()
	return TRUE

/obj/machinery/coffeemaker/RefreshParts()
	. = ..()
	speed = 0
	//for(var/datum/stock_part/micro_laser/laser in component_parts)
	//	speed += laser.rating

/obj/machinery/coffeemaker/attack_hand(mob/user)
	. = ..()
	if (.)
		return
	return interact(user)

/obj/machinery/coffeemaker/interact(mob/user)
	ui_interact(user)
	//wires.interact(user)

/obj/machinery/coffeemaker/attackby(obj/item/attacking_item, mob/user, list/modifiers)
	. = ..()
	if(panel_open) //Can't insert objects when its screwed open
		return TRUE

	if (istype(attacking_item, /obj/item/reagent_containers/glass/beaker/pitcher) && !is_abstract(attacking_item) && attacking_item.is_open_container())
		var/obj/item/reagent_containers/glass/beaker/pitcher/new_pot = attacking_item
		. = TRUE //no afterattack
		user.remove_from_mob(new_pot)
		new_pot.forceMove(src)
		replace_pot(user, new_pot)
		update_icon()
		return TRUE //no afterattack

	if (istype(attacking_item, /obj/item/reagent_containers/food/drinks/takeaway_cup) && !is_abstract(attacking_item) && attacking_item.is_open_container())
		var/obj/item/reagent_containers/food/drinks/takeaway_cup/new_cup = attacking_item
		if(!istype(new_cup, initial_cup))
			balloon_alert(user, "brand conflict detected!")
			return
		if(new_cup.reagents.total_volume > 0)
			balloon_alert(user, "the cup must be empty!")
			return
		if(coffee_cups >= max_coffee_cups)
			balloon_alert(user, "the cup holder is full!")
			return
		user.remove_from_mob(new_cup)
		new_cup.forceMove(src)
		coffee_cups++
		update_icon()
		return TRUE //no afterattack

	if (istype(attacking_item, /obj/item/reagent_containers/food/condiment/small/packet/sugar))
		var/obj/item/reagent_containers/food/condiment/small/packet/sugar/new_pack = attacking_item
		if(new_pack.reagents.total_volume < new_pack.reagents.maximum_volume)
			balloon_alert(user, "the pack must be full!")
			return
		if(sugar_packs >= max_sugar_packs)
			balloon_alert(user, "the sugar compartment is full!")
			return
		user.remove_from_mob(new_pack)
		new_pack.forceMove(src)
		sugar_packs++
		update_icon()
		return TRUE //no afterattack

	if (istype(attacking_item, /obj/item/reagent_containers/food/condiment/small/packet/cream))
		var/obj/item/reagent_containers/food/condiment/small/packet/cream/new_pack = attacking_item
		if(new_pack.reagents.total_volume < new_pack.reagents.maximum_volume)
			balloon_alert(user, "the pack must be full!")
			return
		if(creamer_packs >= max_creamer_packs)
			balloon_alert(user, "the creamer compartment is full!")
			return
		user.remove_from_mob(new_pack)
		new_pack.forceMove(src)
		creamer_packs++
		update_icon()
		return TRUE //no afterattack

	if (istype(attacking_item, /obj/item/reagent_containers/food/condiment/small/packet/phenyltame))
		var/obj/item/reagent_containers/food/condiment/small/packet/phenyltame/new_pack = attacking_item
		if(new_pack.reagents.total_volume < new_pack.reagents.maximum_volume)
			balloon_alert(user, "the pack must be full!")
			return
		else if(sweetener_packs >= max_sweetener_packs)
			balloon_alert(user, "the sweetener compartment is full!")
			return
		user.remove_from_mob(new_pack)
		new_pack.forceMove(src)
		sweetener_packs++
		update_icon()
		return TRUE //no afterattack

	if (istype(attacking_item, /obj/item/coffee_cartridge) && !(is_abstract(attacking_item)))
		var/obj/item/coffee_cartridge/new_cartridge = attacking_item
		user.remove_from_mob(new_cartridge)
		new_cartridge.forceMove(src)
		replace_cartridge(user, new_cartridge)
		balloon_alert(user, "added cartridge")
		update_icon()
		return TRUE //no afterattack

/obj/machinery/coffeemaker/proc/try_brew_from_cartridge(mob/user)
	if(!cartridge)
		balloon_alert(user, "no coffee cartridge inserted!")
		return FALSE
	if(cartridge.charges < 1)
		balloon_alert(user, "coffee cartridge empty!")
		return FALSE
	if(!coffeepot)
		balloon_alert(user, "no coffeepot inside!")
		return FALSE
	if(stat & (NOPOWER|BROKEN))
		balloon_alert(user, "machine unpowered!")
		return FALSE
	if(coffeepot.reagents.total_volume >= coffeepot.reagents.maximum_volume)
		balloon_alert(user, "the coffeepot is already full!")
		return FALSE
	return TRUE

/obj/machinery/coffeemaker/proc/try_brew_from_beans(mob/user)
	if(coffee_amount <= 0)
		balloon_alert(user, "no coffee beans added!")
		return FALSE
	if(!coffeepot)
		balloon_alert(user, "no coffeepot inside!")
		return FALSE
	if(stat & (NOPOWER|BROKEN) )
		balloon_alert(user, "machine unpowered!")
		return FALSE
	if(coffeepot.reagents.total_volume >= coffeepot.reagents.maximum_volume)
		balloon_alert(user, "the coffeepot is already full!")
		return FALSE
	return TRUE

/obj/machinery/coffeemaker/ui_interact(mob/user)
	. = ..()
	if(brewing)
		return

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
		choice = show_radial_menu(user, src, options)
//require_near = !HAS_SILICON_ACCESS(user)
	// post choice verification
	if(brewing || (isAI(user) && stat & NOPOWER))
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
	var/obj/item/new_cup = new initial_cup(get_turf(src))
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
	if(!sugar_packs)
		balloon_alert(user, "no sweetener left!")
		return
	var/obj/item/reagent_containers/food/condiment/small/packet/phenyltame/new_pack = new(get_turf(src))
	user.put_in_hands(new_pack)
	sweetener_packs--
	update_icon()

/obj/machinery/coffeemaker/proc/take_creamer(mob/user)
	if(!creamer_packs)
		balloon_alert(user, "no creamer left!")
		return
	var/obj/item/reagent_containers/food/condiment/small/packet/cream/new_pack = new(get_turf(src))
	user.put_in_hands(new_pack)
	creamer_packs--
	update_icon()

/obj/machinery/coffeemaker/proc/replace_cartridge(mob/living/user, obj/item/coffee_cartridge/new_cartridge)
	if(!user)
		return FALSE
	if(cartridge)
		user.put_in_hands(cartridge)
	if(new_cartridge)
		cartridge = new_cartridge
	update_icon()
	return TRUE

/obj/machinery/coffeemaker/proc/operate_for(time, silent = FALSE)
	brewing = TRUE
	//if(!silent)
		//playsound(src, 'sound/machines/coffeemaker_brew.ogg', 20, vary = TRUE)
	//toggle_steam()
	//use_energy(active_power_usage * time / (1 SECONDS)) // .1 needed here to convert time (in deciseconds) to seconds such that watts * seconds = joules
	addtimer(CALLBACK(src, PROC_REF(stop_operating)), time / speed)

/obj/machinery/coffeemaker/proc/stop_operating()
	brewing = FALSE
	//toggle_steam()

/obj/machinery/coffeemaker/proc/brew(user)
	power_change()
	if(!try_brew_from_cartridge(user))
		return
	operate_for(brew_time)
	coffeepot.reagents.add_reagent()
	for(var/drink as anything in cartridge.drink_type)
		var/amount = cartridge.drink_type[drink]
		coffeepot.reagents.add_reagent(drink, amount, temperature = STANDARD_COFFEE_TEMPERATURE)
	cartridge.charges--
	update_icon()

/obj/machinery/coffeemaker/cartridge/standard
	name = "coffeemaker"
	desc = "A Modello 4 Coffeemaker that brews coffee and holds it at the perfect temperature of 90° Celcius. Made by Piccionaia Home Appliances, a known subsidiary of Getmore Corporation."
	initial_cartridge = /obj/item/coffee_cartridge

//Coffee Cartridges: like toner, but for your coffee!
ABSTRACT_TYPE(/obj/item/coffee_cartridge)
	name = "coffeemaker cartridge"
	desc = DESC_PARENT
	icon = 'icons/obj/item/cartridges.dmi'
	icon_state = "cartridge_basic"
	///Amount of charges present/remaining on the cartridge
	var/charges = 4
	///List of drink types to produce in a single charge.
	var/list/drink_type = list(/singleton/reagent/drink/coffee = 120)

/obj/item/coffee_cartridge/get_examine_text(mob/user, distance, is_adjacent, infix, suffix, get_extended)
	. = ..()
	if(!is_adjacent)
		return
	if(charges)
		. += SPAN_NOTICE("The cartridge has [charges] portions of grounds remaining.")
	else
		. += SPAN_WARNING("The cartridge has no unspent grounds remaining.")

/obj/item/coffee_cartridge/generic
	name = "coffeemaker cartridge - Caffè Generico"
	desc = "A coffee cartridge manufactured by Piccionaia Coffee, for use with the Modello 3 system."

/obj/item/coffee_cartridge/fancy
	name = "coffeemaker cartridge - Caffè Fantasioso"
	desc = "A fancy coffee cartridge manufactured by Piccionaia Coffee, for use with the Modello 3 system."
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

//We lack a decaffeinated coffee reagent, for now this is roleplay-only
/obj/item/coffee_cartridge/decaf
	name = "coffeemaker cartridge - Caffè Decaffeinato"
	desc = "A decaf coffee cartridge manufactured by Piccionaia Coffee, for use with the Modello 3 system."
	icon_state = "cartridge_decaf"

/obj/item/coffee_cartridge/hot_coco
	name = "coffeemaker cartridge - Hot Chocolate"
	desc = "A hot chocolate cartridge manufactured by Piccionaia Coffee, for use with the Modello 3 system."
	drink_type = list(/singleton/reagent/drink/hot_coco = 120)


#undef BEAN_CAPACITY
#undef STANDARD_COFFEE_TEMPERATURE
