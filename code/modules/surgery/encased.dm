//Procedures in this file: Generic ribcage opening steps, Removing alien embryo, Fixing internal organs.
//////////////////////////////////////////////////////////////////
//				GENERIC	RIBCAGE SURGERY							//
//////////////////////////////////////////////////////////////////
/singleton/surgery_step/open_encased
	name = "Saw Through Bone"
	allowed_tools = list(
	/obj/item/surgery/circular_saw = 100,
	/obj/item/melee/energy = 100,
	/obj/item/melee/chainsword = 70,
	/obj/item/material/hatchet = 75
	)
	can_infect = TRUE
	blood_level = 1
	min_duration = 30
	max_duration = 50
	shock_level = 60
	delicate = TRUE
	surgery_candidate_flags = SURGERY_NO_ROBOTIC | SURGERY_NEEDS_RETRACTED
	strict_access_requirement = TRUE

/singleton/surgery_step/open_encased/assess_bodypart(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = ..()
	if(affected && affected.encased)
		return affected

/singleton/surgery_step/open_encased/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	user.visible_message("[user] begins to cut through [target]'s [affected.encased] with \the [tool].", \
		"You begin to cut through [target]'s [affected.encased] with \the [tool].")
	target.custom_pain("Something hurts horribly in your [affected.name]!", 75, affecting = affected)
	..()

/singleton/surgery_step/open_encased/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)

	user.visible_message("<b>[user]</b> has cut [target]'s [affected.encased] open with \the [tool].",		\
		SPAN_NOTICE("You have cut [target]'s [affected.encased] open with \the [tool]."))
	affected.fracture()
	..()

/singleton/surgery_step/open_encased/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(SPAN_WARNING("[user]'s hand slips, cracking [target]'s [affected.encased] with \the [tool]!") , \
		SPAN_WARNING("Your hand slips, cracking [target]'s [affected.encased] with \the [tool]!") )
	target.apply_damage(20, DAMAGE_BRUTE, target_zone, 0, tool, damage_flags = tool.damage_flags(), used_weapon = tool)
	affected.fracture()
	..()
