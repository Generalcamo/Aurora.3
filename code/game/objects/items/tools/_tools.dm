// This file defines the abstract layer used for most tools. Engineering and medical are common places to use tools, but more could be added in the future.

ABSTRACT_TYPE(/obj/item/tool)
	name = "tool"
	desc = DESC_PARENT
	icon = 'icons/obj/tools.dmi'
	item_icons = list(
		slot_l_hand_str = 'icons/mob/items/lefthand_tools.dmi',
		slot_r_hand_str = 'icons/mob/items/righthand_tools.dmi',
		)
	obj_flags = OBJ_FLAG_CONDUCTABLE
	slot_flags = SLOT_BELT
	force = 18
	throwforce = 7
	w_class = WEIGHT_CLASS_SMALL
	origin_tech = list(TECH_MATERIAL = 1, TECH_ENGINEERING = 1)
	matter = list(DEFAULT_WALL_MATERIAL = 150)
	attack_verb = list("bashed", "battered", "bludgeoned", "whacked")

	/// Is this tool currently being used?
	var/tool_in_use = FALSE

	var/toggleable = FALSE	//Determines if it can be switched ON or OFF, for example, if you need a tool that will consume power/fuel upon turning it ON only. Such as welder.
	var/switched_on = FALSE	//Curent status of tool. Dont edit this in subtypes vars, its for procs only.
	var/switched_on_qualities	//This var will REPLACE tool_qualities when tool will be toggled on.
	var/switched_on_force
	var/switched_on_hitsound
	var/switched_off_qualities	//This var will REPLACE tool_qualities when tool will be toggled off. So its possible for tool to have diferent qualities both for ON and OFF state.

	/// A list of the tool's qualities.
	var/list/tool_qualities
