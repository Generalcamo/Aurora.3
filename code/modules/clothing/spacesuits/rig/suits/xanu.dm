/obj/item/rig/zero/xanu
	name = "\improper Xanan null suit control module"
	suit_type = "Null hardsuit"
	desc = "A very lightweight suit designed to allow use inside mechs and starfighters, designed specially for the Xanan spacefleet. It feels like you're wearing nothing at all."
	desc_extended = "The dNAXS-26 'null' hardsuit was designed by d.N.A Defense at the request of the All-Xanu Spacefleet, for its spaceborne mech and starfighter pilots. Designed with comfort and mobility in mind, this suit allows pilots their full range of motion, while protecting them from minor radiation hazards and the vacuum of space."
	icon = 'icons/clothing/rig/xanu_zero_suit.dmi'
	icon_state = "xanu_zero"
	species_restricted = list(BODYTYPE_HUMAN, BODYTYPE_IPC_BISHOP, BODYTYPE_IPC_ZENGHU)
	//This suit has no slowdown. These armor values are intentionally terrible as a result.
	armor = list(
		bomb = ARMOR_BOMB_MINOR,
		bio = ARMOR_BIO_SHIELDED,
		rad = ARMOR_RAD_MINOR
	)
	slowdown = 0
	offline_slowdown = 1

	allowed_module_types = MODULE_GENERAL | MODULE_UTILITY

	chest_type = /obj/item/clothing/suit/space/rig/zero/xanu
	helm_type = /obj/item/clothing/head/helmet/space/rig/zero/xanu
	boot_type = null
	glove_type = null
	max_pressure_protection = null
	min_pressure_protection = 0

/obj/item/clothing/head/helmet/space/rig/zero/xanu
	camera = null
	species_restricted = list(BODYTYPE_HUMAN, BODYTYPE_IPC_BISHOP, BODYTYPE_IPC_ZENGHU)
	desc = "A specially designed helmet, allowing a full range of vision. A state of the art holographic display provides a stream of information."

//All in one suit
/obj/item/clothing/suit/space/rig/zero/xanu
	species_restricted = list(BODYTYPE_HUMAN, BODYTYPE_IPC_BISHOP, BODYTYPE_IPC_ZENGHU)
	//Worse protection than most hardsuits, due to no slowdown
	breach_threshold = 18
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS|FEET|ARMS|HANDS
	allowed = list(
		/obj/item/device/flashlight,
		/obj/item/tank,
		/obj/item/device/suit_cooling_unit
	)
