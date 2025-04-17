/*
 * Wrench
 */
/obj/item/tool/wrench
	name = "wrench"
	desc = "An adjustable tool used for gripping and turning nuts or bolts."
	icon_state = "wrench"
	item_state = "wrench"
	matter = list(DEFAULT_WALL_MATERIAL = 150)
	usesound = 'sound/items/wrench.ogg'
	surgerysound = 'sound/items/surgery/bonesetter.ogg'
	drop_sound = 'sound/items/drop/wrench.ogg'
	pickup_sound = 'sound/items/pickup/wrench.ogg'

	tool_qualities = list(
		QUALITY_BOLT_TURNING = 30,
		QUALITY_HAMMERING = 10,
	)
