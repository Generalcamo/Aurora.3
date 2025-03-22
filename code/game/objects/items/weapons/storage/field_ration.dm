/obj/item/storage/field_ration
	name = "field ration"
	desc = "An individually packed meal, designated to be consumed on field."
	icon = 'icons/obj/tajara_items.dmi'
	icon_state = "ration"
	desc_extended = "The republican army is the best equipped among the warring factions of Adhomai, being supplied by NanoTrasen and other outworld supporters. Canned goods and \
	modern rations are issued to all branches of the Republic's military. Native field meals are composed of salt-cured Fatshouters's meat, bread and Victory Gin, while imported ones \
	are commonly found in the form of LiquidFood rations, a less than popular alternative manufactured by NanoTrasen."
	var/preset_ration	//if the package comes with one in particular, not a random
	make_exact_fit = TRUE

/obj/item/storage/field_ration/fill()
	..()
	new /obj/item/material/kitchen/utensil/spoon(src)
	create_ration()

/obj/item/storage/field_ration/proc/create_ration()
	var/selected_ration = preset_ration
	if(!selected_ration)
		selected_ration = pick("Worker's Meal", "NanoTrasen Sponsored")

	switch(selected_ration)

		if("Worker's Meal")
			new /obj/item/reagent_containers/food/snacks/tajaran_bread(src)
			new /obj/item/reagent_containers/food/snacks/adhomian_can(src)
			new /obj/item/reagent_containers/food/drinks/bottle/victorygin(src)
			desc += " This one has the stamp of the Republican Army."

		if("NanoTrasen Sponsored")
			new /obj/item/reagent_containers/food/snacks/liquidfood(src)
			new /obj/item/reagent_containers/food/snacks/liquidfood(src)
			new /obj/item/reagent_containers/food/drinks/cans/hrozamal_soda(src)
			desc += " This one has the NanoTrasen logo."

/obj/item/storage/field_ration/army
	preset_ration = "Worker's Meal"

/obj/item/storage/field_ration/nanotrasen
	preset_ration = "NanoTrasen Sponsored"

/obj/item/storage/field_ration/nka
	icon_state = "bigbox_nka"
	desc_extended = "The early Alam'ardii forces relied on the landed nobility to provide them food, with the resources being taken from the private properties of their contractors. \
	Their rations were composed mainly of salt-cured Snow Strider's meat, Blizzard Ears's flour and Fatshouters's milk. The defection of many officers from the Republican navy to the \
	imperial side introduced the concept of canned goods, a luxury at the time, being used as rations. Large shipments of supplements, included food, were smuggled by the officers and \
	their crew during the formation of the Royal Navy."

/obj/item/storage/field_ration/nka/create_ration()
	var/selected_ration = preset_ration
	if(!selected_ration)
		selected_ration = pick("Imperial Army", "Royal Navy")

	switch(selected_ration)

		if("Imperial Army")
			new /obj/item/reagent_containers/food/snacks/hardbread(src)
			new /obj/item/reagent_containers/food/drinks/cans/adhomai_milk(src)
			desc += " This one has the stamp of the Imperial Adhomian Army."

		if("Royal Navy")
			new /obj/item/reagent_containers/food/snacks/hardbread(src)
			new /obj/item/reagent_containers/food/snacks/adhomian_can(src)
			new /obj/item/reagent_containers/food/drinks/bottle/messa_mead(src)
			desc += " This one has the stamp of the Royal Navy."

/obj/item/storage/field_ration/nka/army
	preset_ration = "Imperial Army"

/obj/item/storage/field_ration/nka/navy
	preset_ration = "Royal Navy"

/obj/item/storage/field_ration/dpra
	icon_state = "bigbox"
	desc_extended = "The Adhomai Liberation army only recently since the transition to civilian government, created a standard set of rations for its military forces.\ 
	Forces within areas controlled by the civilian government, as well as some warlords, use the standard rations. Manufactured in the industrial sectors in Das'nraa\
	and Southern Ras'nrr, it promises to be nutritious and filling for most circumstances, though the reception amongst Liberation Army forces has only been mildly warmer\
	than the old, scraped-together rations that the ALA used to use."

/obj/item/storage/field_ration/dpra/create_ration()
	new /obj/item/reagent_containers/food/snacks/explorer_ration(src)
	new /obj/item/reagent_containers/food/snacks/tajaran_bread(src)
	new /obj/item/reagent_containers/food/drinks/cans/adhomai_milk(src)
	desc += " This one has the stamp of the Adhomai Liberation Army."

/obj/item/storage/field_ration/dpra/ala
	desc_extended = "While the Democratic People's Republic of Adhomai has defined a standard ration for its forces, certain forces are unable or unwilling to utilize them.\
	The traditional ration of the Adhomai Liberation army, being an amalgamation of regular army units, militia groups, and undercover agents, is non-standard and depending on the locale. \
	Depending on the area where one army might operate, its commanding officer, and available resources, rations might range from industrialized goods to foraging and hunting."

/obj/item/storage/field_ration/dpra/ala/dinakk
	preset_ration = "Din'akk Mountains"

/obj/item/storage/field_ration/dpra/ala/south_harrmasir
	preset_ration = "Southern Harr'masir"

/obj/item/storage/field_Ration/dpra/ala/north_rasnrr
	preset_ration = "Northern Ras'nrr"

/obj/item/storage/field_ration/ala/create_ration()
	var/selected_ration = preset_ration
	if(!selected_ration)
		selected_ration = pick("Din'akk Mountains", "Southern Harr'masir", "Northern Ras'nrr")

	switch(selected_ration)

		if("Din'akk Mountains")
			desc += " This one seems to be of a higher quality than most Adhomaian rations, and is stocked with more luxurious goods (taken from off-world) than most rations have."

		if("Southern Harr'masir")
			desc += " This one is a simple ration, using more local products. It seems to conform to the standards established by the DPRA, but with substitutions available for if supply lines are cut off."

		if("Northern Ras'nrr")
			desc += " This is a makeshift ration, clearly manufactured from whatever could be scrounged up, or seized from local villages."
