/* SURGERY STEPS */

ABSTRACT_TYPE(/singleton/surgery_step)
	/// An identifying name string.
	var/name

	/// type path referencing tools that can be used for this step, and how well are they suited for it
	var/list/allowed_tools = null
	/// type paths referencing species that this step applies to.
	var/list/allowed_species = null
	/// type paths referencing species that this step never applies to.
	var/list/disallowed_species = list("Nymph")
	/// Minimum duration of the step
	var/min_duration = 0
	/// Maximum duration of the step
	var/max_duration = 0
	/// if this step NEEDS stable optable or can be done on any valid surface with no penalty
	var/delicate = FALSE
	/// Various bitflags for requirements of the surgery.
	var/surgery_candidate_flags = 0
	/// Whether or not this surgery will be fuzzy on size requirements.
	var/strict_access_requirement = TRUE
	/// what shock level will this step put patient on
	var/shock_level = 0
	/// Whether this step can cause an infection, if the surgeon is not clean
	var/can_infect = FALSE
	//How much blood this step can get on surgeon. 1 - hands, 2 - full body.
	var/blood_level = 0
	var/requires_surgery_compatibility = TRUE
	/// Sound (or list of sounds) to play on end step.
	var/end_step_sound = "rustle"
	/// Sound (or list of sounds) to play on fail step.
	var/fail_step_sound
	/// Sound (or list of sounds) to play on begin step.
	var/begin_step_sound = "rustle"

/singleton/surgery_step/proc/is_self_surgery_permitted(mob/target, bodypart)
	return TRUE

///Returns how well tool is suited for this step
/singleton/surgery_step/proc/tool_quality(obj/item/tool)
	for(var/T in allowed_tools)
		var/return_value = check_tool_quality(tool, T, allowed_tools[T], requires_surgery_compatibility)
		if(return_value)
			return return_value
		if(istype(tool,T))
			return allowed_tools[T]
	return FALSE

///Checks if this step applies to the user mob at all
/singleton/surgery_step/proc/is_valid_target(mob/living/carbon/human/target)
	if(!ishuman(target))
		return FALSE

	if(allowed_species)
		for(var/species in allowed_species)
			if(target.species.get_bodytype() == species)
				return TRUE

	if(disallowed_species)
		for(var/species in disallowed_species)
			if(target.species.get_bodytype() == species)
				return FALSE

	return TRUE

// checks whether this step can be applied with the given user and target
/singleton/surgery_step/proc/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return assess_bodypart(user, target, target_zone, tool) && assess_surgery_candidate(user, target, target_zone, tool)

/singleton/surgery_step/proc/assess_bodypart(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(istype(target) && target_zone)
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		if(affected)
			// Check various conditional flags
			if((surgery_candidate_flags & SURGERY_NO_ROBOTIC) && BP_IS_ROBOTIC(affected))
				FEEDBACK_FAILURE(user, "You notice that \the [target.name] in [user]'s [affected.name] is a mechanical organ, and you cannot perform this task with a mechanical organ.")
				return FALSE
			if((surgery_candidate_flags & SURGERY_NO_FLESH) && !(BP_IS_ROBOTIC(affected)))
				FEEDBACK_FAILURE(user, "You notice that \the [target.name] in [user]'s [affected.name] is a biological organ, and you cannot perform this task with a biological organ.")
				return FALSE
			if((surgery_candidate_flags & SURGERY_NO_STUMP) && affected.is_stump())
				FEEDBACK_FAILURE(user, "\The [user]'s [affected.name] is nothing but a stump! You cannot perform this task with a stump!")
				return FALSE
			// Check if the surgery target is accessible
			if(BP_IS_ROBOTIC(affected))
				if(((surgery_candidate_flags & SURGERY_NEEDS_ENCASEMENT) || \
				(surgery_candidate_flags & SURGERY_NEEDS_RETRACTED) || \
				(surgery_candidate_flags & SURGERY_NEEDS_INCISION)) && \
				affected.hatch_state != HATCH_OPENED)
					return FALSE
//			else
//				var/open_threshold
//				if(surgery_candidate_flags & SURGERY_NEEDS_INCISION)
//					//open_threshold = SURGERY_OPEN
//				else if(surgery_candidate_flags & SURGERY_NEEDS_RETRACTED)
//					//open_threshold = SURGERY_RETRACTED
//				else if(surgery_candidate_flags & SURGERY_NEEDS_ENCASEMENT)
					//open_threshold = (affected.encased ? SURGERY_ENCASED : SURGERY_RETRACTED)
				//if(open_threshold && ((strict_access_requirement && affected.how_open() != open_threshold) || affected.how_open() < open_threshold))
				//	return FALSE
			// Check if clothing is blocking access
			var/obj/item/I = target.get_covering_equipped_item_by_zone(target_zone)
			if(I?.item_flags & ITEM_FLAG_THICK_MATERIAL)
				FEEDBACK_FAILURE(user, "The [I.name] covering [target]'s [parse_zone(target_zone)] is too thick for you to do surgery through!")
				return FALSE
			return affected
	return FALSE

/singleton/surgery_step/proc/assess_surgery_candidate(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return ishuman(target)

// does stuff to begin the step, usually just printing messages. Moved germs transfering and bloodying here too
/singleton/surgery_step/proc/begin_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(can_infect && affected)
		spread_germs_to_organ(affected, user)
	if(ishuman(user) && prob(60))
		var/mob/living/carbon/human/H = user
		if(blood_level)
			H.bloody_hands(target,0)
		if(blood_level > 1)
			H.bloody_body(target,0)
	if(shock_level)
		target.shock_stage = max(target.shock_stage, shock_level)
	playsound(target.loc, tool.surgerysound, 50, TRUE)
	return TRUE

/// does stuff to end the step, which is normally print a message + do whatever this step changes
/singleton/surgery_step/proc/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
//	SHOULD_CALL_PARENT(TRUE)
	if(end_step_sound)
		playsound(target, pick(end_step_sound), 15, TRUE)

/// stuff that happens when the step fails
/singleton/surgery_step/proc/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
//	SHOULD_CALL_PARENT(TRUE)
	if(fail_step_sound)
		playsound(target, pick(fail_step_sound), 15, TRUE)
	return null

/proc/spread_germs_to_organ(var/obj/item/organ/external/E, var/mob/living/carbon/human/user)
	if(!istype(user) || !istype(E))
		return FALSE

	var/germ_level = user.germ_level
	if(user.gloves)
		germ_level = user.gloves.germ_level

	E.germ_level = max(germ_level,E.germ_level) //as funny as scrubbing microbes out with clean gloves is - no.

/proc/do_surgery(mob/living/carbon/M, mob/living/user, obj/item/tool, var/autofail = FALSE)
	// Check for the Hippocratic oath.
	if(!istype(M) || user.a_intent == I_HURT)
		return FALSE

	// Check for multi-surgery drifting.
	var/zone = user.zone_sel.selecting
	if(zone in M.op_stage.in_progress)
		to_chat(user, SPAN_WARNING("You can't operate on this area while surgery is already in progress."))
		return TRUE

	// What surgeries does our tool/target enable?
	var/list/possible_surgeries
	var/list/all_surgeries = GET_SINGLETON_SUBTYPE_MAP(/singleton/surgery_step)
	for(var/singleton as anything in all_surgeries)
		var/singleton/surgery_step/S = all_surgeries[singleton]
		if(S.name && S.tool_quality(tool) && S.can_use(user, M, zone, tool))
			var/image/radial_button = image(icon = tool.icon, icon_state = tool.icon_state)
			radial_button.name = S.name
			LAZYSET(possible_surgeries, S, radial_button)

	// Which surgery, if any, do we actually want to do?
	var/cancelled_surgery = FALSE
	var/singleton/surgery_step/S
	if(LAZYLEN(possible_surgeries) == 1)
		S = possible_surgeries[1]
	else if (LAZYLEN(possible_surgeries) >= 1)
		if(!user.client) // In case of future autodocs
			S = possible_surgeries[1]
		else
			S = show_radial_menu(user, M, possible_surgeries, radius = 42, tooltips = TRUE, require_near = TRUE, use_labels = TRUE)
			if(!istype(S))
				cancelled_surgery = TRUE

	// We didn't find a surgery, or decided not to perform one.
	if(!istype(S))

		// If they cancelled, do not continue at all!
		if(cancelled_surgery)
			return TRUE

		if(tool.item_flags & ITEM_FLAG_SURGERY) //Is this supposed to be used for surgery?
			to_chat(user, SPAN_WARNING("You aren't sure what you could do to \the [M] with \the [tool]."))
			return TRUE

		return FALSE

	// Otherwise we can make a start on surgery!
	else if(istype(M) && !QDELETED(M) && tool)
		// Double-check this in case it changed between initial check and now.
		if(zone in M.op_stage.in_progress)
			USE_FEEDBACK_FAILURE("You can't operate on this area while surgery is already in progress.")
		else if(S.is_valid_target(M) && S.can_use(user, M, zone, tool))
			M.op_stage.in_progress += list(zone = user)
			try
				S.begin_step(user, M, zone, tool)
				var/duration = rand(S.min_duration, S.max_duration) / get_location_modifier(M)
				var/do_result = do_after_detailed(user, duration, M, DO_SURGERY)
				var/do_surgery_result = SURGERY_IGNORE
				switch(do_result)
					if(DO_MISSING_TARGET)
						USE_FEEDBACK_FAILURE("\The [M] no longer exists!")
					if(DO_INCAPACITATED)
						to_chat(user, SPAN_DANGER("Your [tool.name] slips as you become incapacitated!"))
						do_surgery_result = SURGERY_FAIL
					if(DO_USER_CAN_MOVE)
						to_chat(user, SPAN_DANGER("Your [tool.name] slips as you move!"))
						do_surgery_result = SURGERY_FAIL
					if(DO_TARGET_CAN_MOVE)
						to_chat(user, SPAN_DANGER("Your [tool.name] slips as \the [M] moves!"))
						do_surgery_result = SURGERY_FAIL
					if(DO_USER_CAN_TURN)
						to_chat(user, SPAN_DANGER("Your [tool.name] slips as you turn!"))
						do_surgery_result = SURGERY_FAIL
					if(DO_TARGET_CAN_TURN)
						to_chat(user, SPAN_DANGER("Your [tool.name] slips as \the [M] turns!"))
						do_surgery_result = SURGERY_FAIL
					if(DO_USER_SAME_HAND)
						USE_FEEDBACK_FAILURE("You must remain on the same active hand to perform that action!")
					if(DO_USER_UNIQUE_ACT)
						USE_FEEDBACK_FAILURE("You stop what you're doing with \the [M].")
					if(DO_USER_SAME_ZONE)
						USE_FEEDBACK_FAILURE("You must remain targeting the same zone to perform that action!")
					if(FALSE)
						do_surgery_result = SURGERY_SUCCESS
				if(do_surgery_result == SURGERY_SUCCESS)
					if(!prob(S.success_chance(user, M, tool, zone)))
						do_surgery_result = SURGERY_FAIL
				if(do_surgery_result == SURGERY_SUCCESS)
					S.end_step(user, M, zone, tool)
				else if (do_surgery_result == SURGERY_FAIL)
					S.fail_step(user, M, zone, tool)
			catch(var/exception/E)
				stack_trace("Exception during surgery: [E]")
			if(!QDELETED(M))
				M.op_stage.in_progress -= list(zone = user)
				if(ishuman(M))
					var/mob/living/carbon/human/H = M
					H.update_surgery()
		return TRUE
	return FALSE

/singleton/surgery_step/proc/success_chance(mob/living/user, mob/living/carbon/human/target, obj/item/tool, target_zone)
	. = tool_quality(tool)
	//Self-surgery has a 10% flat penalty
	if(user == target)
		. -= 10

	//Being drugged has a 25% flat penalty
	if(user.druggy)
		. -= 25

	// TODO: Skill checks

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		. -= round(H.shock_stage * 0.5)
		// Vision impairment is very bad for surgery.
		if(H.eye_blind)
			. -= 70
		else if(H.eye_blurry)
			. -= 20
		// Don't drink and operate
		if(H.is_drunk())
			. -= 25

	if(delicate)
		. *= get_location_modifier(target)

	. = max(., 0)

/proc/get_location_modifier(mob/located_mob)
	var/static/list/modifiers = list(
		/obj/structure/table = 0.66,
		/obj/structure/bed/roller = 0.8,
		/obj/structure/bed = 0.7,
		/obj/machinery/stasis_bed = 0.8,
		/obj/machinery/optable = 1.0,
		/obj/effect/rune = 0.6
	)
	. = 0.5
	for(var/obj/thingy in get_turf(located_mob))
		. = max(., modifiers[thingy.type])

/datum/surgery_status
	var/eyes = 0
	var/face = 0
	var/head_reattach = 0
	var/current_organ = "organ"
	var/list/in_progress = list()

/datum/surgery_status/Destroy(force)
	in_progress = null
	. = ..()
