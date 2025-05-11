///Defines how much oxyloss humans can get per tick. A tile with no air at all (such as space) applies this value, otherwise it's a percentage of it.
#define HUMAN_MAX_OXYLOSS 1
///Determines the exchange ratio of reagents being converted to gas and vice versa.
#define REAGENT_GAS_EXCHANGE_FACTOR 10

/obj/item/organ/internal/lungs
	name = "lungs"
	desc = "Think of them as a portable air alarm! If something's wrong with the atmosphere, they'll let you know right away."
	icon_state = "lungs"
	gender = PLURAL
	organ_tag = BP_LUNGS
	parent_organ = BP_CHEST
	robotic_name = "gas exchange system"
	min_bruised_damage = 30
	min_broken_damage = 45
	toxin_type = CE_PNEUMOTOXIC

	max_damage = 80
	relative_size = 60

	var/breath_type
	var/exhale_type
	var/list/poison_type

	var/min_breath_pressure
	var/last_int_pressure
	var/last_ext_pressure
	var/max_pressure_diff = 60

	// Handles rupture grace period
	var/rupture_imminent = FALSE // If this is true and the pressure is too high or low, our lungs will rupture
	var/checking_rupture = TRUE // If this is false, the rupture check won't run, granting a grace period

	var/rescued = FALSE // whether or not a collapsed lung has been rescued with a syringe
	var/oxygen_deprivation = 0
	var/safe_toxins_max = 0.2
	var/breathing = 0
	var/last_successful_breath
	var/breath_fail_ratio //How badly they failed a breath

	var/datum/reagents/metabolism/inhaled

/obj/item/organ/internal/lungs/Destroy()
	QDEL_NULL(inhaled)
	. = ..()

/obj/item/organ/internal/lungs/proc/remove_oxygen_deprivation(var/amount)
	var/last_suffocation = oxygen_deprivation
	oxygen_deprivation = min(species.total_health,max(0,oxygen_deprivation - amount))
	return -(oxygen_deprivation - last_suffocation)

/obj/item/organ/internal/lungs/proc/add_oxygen_deprivation(var/amount)
	var/last_suffocation = oxygen_deprivation
	oxygen_deprivation = min(species.total_health,max(0,oxygen_deprivation + amount))
	return (oxygen_deprivation - last_suffocation)

// Returns a percentage value for use by GetOxyloss().
/obj/item/organ/internal/lungs/proc/get_oxygen_deprivation()
	if(status & ORGAN_DEAD)
		return 100
	return round((oxygen_deprivation/species.total_health)*100)

/obj/item/organ/internal/lungs/set_dna(datum/dna/new_dna)
	sync_breath_types()

/obj/item/organ/internal/lungs/replaced()
	sync_breath_types()

/**
 *  Set these lungs' breath types based on the lungs' species
 */
/obj/item/organ/internal/lungs/proc/sync_breath_types()
	if(species)
		//max_pressure_diff = species.max_pressure_diff
		min_breath_pressure = species.breath_pressure
		breath_type = species.breath_type ? species.breath_type : GAS_OXYGEN
		exhale_type = species.exhale_type ? species.exhale_type : GAS_CO2
		poison_type = species.poison_types ? species.poison_types : list(GAS_PHORON = TRUE)
	else
		max_pressure_diff = initial(max_pressure_diff)
		min_breath_pressure = initial(min_breath_pressure)
		breath_type = GAS_OXYGEN
		exhale_type = GAS_CO2
		poison_type = GAS_PHORON

/obj/item/organ/internal/lungs/process()
	..()

	if(!owner || owner.stat == DEAD)
		return

	if(germ_level > INFECTION_LEVEL_ONE && breathing)
		if(prob(5))
			owner.emote("cough")		//Respiratory tract infection

	if(is_broken() || (is_bruised() && !rescued) && !owner.is_asystole()) // a thoracostomy can only help with a collapsed lung, not a mangled one
		if(prob(2))
			owner.visible_message(
				"<B>\The [owner]</B> coughs up blood!",
				SPAN_WARNING("You cough up blood!"),
				"You hear someone coughing!",
				)
			owner.drip(10)
		if(prob(4))
			owner.visible_message(
				"<B>\The [owner]</B> gasps for air!",
				SPAN_DANGER("You can't breathe!"),
				"You hear someone gasp for air!",
			)
			owner.losebreath = max(round(damage / 2), owner.losebreath)

	if(rescued)
		if(is_bruised())
			if(prob(4))
				to_chat(owner, SPAN_WARNING("It feels hard to breathe..."))
				if (owner.losebreath < 5)
					owner.losebreath = min(owner.losebreath + 1, 5) // it's still not good, but it's much better than an untreated collapsed lung
		else
			if(prob(2))
				to_chat(owner, SPAN_WARNING("It feels hard to breathe, and something in your chest is whistling..."))
				if (owner.losebreath < 2)
					owner.losebreath = min(owner.losebreath + 1, 2)

/obj/item/organ/internal/lungs/proc/rupture()
	var/obj/item/organ/external/parent = owner.get_organ(parent_organ)
	if(istype(parent))
		owner.custom_pain("You feel a stabbing pain in your [parent.name]!", 50, affecting = parent)
	rupture_imminent = FALSE
	bruise()

/obj/item/organ/internal/lungs/proc/handle_failed_breath()
	if(prob(15) && !owner.nervous_system_failure())
		if(!owner.is_asystole())
			if(owner.is_submerged())
				owner.emote("flail")
			else
				owner.emote("gasp")
		else
			owner.emote(pick("shiver","twitch"))

	if(damage || owner.chem_effects[CE_BREATHLOSS] || world.time > last_successful_breath + 2 MINUTES)
		owner.adjustOxyLoss(HUMAN_MAX_OXYLOSS * breath_fail_ratio)
	owner.oxygen_alert = max(owner.oxygen_alert, 2)
	last_int_pressure = 0

//exposure to extreme pressures can rupture lungs
/obj/item/organ/internal/lungs/proc/check_rupturing(breath_pressure)
	if(isnull(last_int_pressure))
		last_int_pressure = breath_pressure
		return
	var/datum/gas_mixture/environment = loc.return_air_for_internal_lifeform()
	var/ext_pressure = environment && environment.return_pressure() // May be null if, say, our owner is in nullspace
	var/int_pressure_diff = abs(last_int_pressure - breath_pressure)
	var/ext_pressure_diff = abs(last_ext_pressure - ext_pressure) * owner.get_pressure_weakness(ext_pressure)
	if(int_pressure_diff > max_pressure_diff && ext_pressure_diff > max_pressure_diff)
		if((last_int_pressure > last_ext_pressure) && (owner.IsEVATrained() || owner.stat > 0) && !owner.internal) //If EVA trained, use special handling
			if(!owner.internal) //If we have no internals, allow exhaling
				if(owner.stat == 0) //Only show the message if conscious
					to_chat(owner, SPAN_WARNING("You feel your lungs expanding from the sudden loss of pressure. Recalling your EVA training, you allow the air to exit your lungs."))
				last_int_pressure = environment.return_pressure()
				return
			else //You'll need to turn off those internals to exhale
				if(owner.stat == 0) //Only show the message if conscious
					to_chat(owner, SPAN_DANGER("You feel your lungs expanding from the sudden loss of pressure! You are trained in EVA, but you can't get rid of the pressure difference with internals on!"))
		var/lung_rupture_prob =BP_IS_ROBOTIC(src) ? prob(30) : prob(60) //Robotic lungs are less likely to rupture.
		if(!is_bruised() && lung_rupture_prob) //only rupture if NOT already ruptured
			rupture()

/obj/item/organ/internal/lungs/proc/enable_rupture()
	rupture_imminent = TRUE
	checking_rupture = TRUE
	addtimer(CALLBACK(src, PROC_REF(disable_rupture)), 5 SECONDS, TIMER_UNIQUE)

/obj/item/organ/internal/lungs/proc/disable_rupture()
	rupture_imminent = FALSE

/obj/item/organ/internal/lungs/proc/handle_breath(datum/gas_mixture/breath)
	if(!owner)
		return 1

	if(!breath || (max_damage <= 0))
		breath_fail_ratio = 1
		handle_failed_breath()
		return 1

	var/breath_pressure
	if(breath.volume)
		breath_pressure = (breath.total_moles * R_IDEAL_GAS_EQUATION * breath.temperature) / (BREATH_VOLUME * owner.species.breath_vol_mul)
	else
		breath_pressure = 0
	check_rupturing(breath_pressure)

	var/datum/gas_mixture/environment = loc.return_air_for_internal_lifeform()
	last_ext_pressure = environment && environment.return_pressure()
	last_int_pressure = breath_pressure
	if(breath.total_moles == 0)
		breath_fail_ratio = 1
		handle_failed_breath()
		return 1

	var/safe_pressure_min = min_breath_pressure // Minimum safe partial pressure of breathable gas in kPa
	// Lung damage increases the minimum safe pressure.
	safe_pressure_min *= 1 + rand(1,4) * damage/max_damage

	var/failed_inhale = 0
	var/failed_exhale = 0

	var/inhaling = breath.gas[breath_type]
	var/inhale_efficiency = min(round(((inhaling/breath.total_moles)*breath_pressure)/safe_pressure_min, 0.001), 3)

	// Not enough to breathe
	if(inhale_efficiency < 1)
		if(prob(20) && breathing)
			if(inhale_efficiency < 0.8)
				if(owner.is_submerged())
					owner.emote("flail")
				else
					owner.emote("gasp")
			else if(prob(20))
				to_chat(owner, SPAN_WARNING("It's hard to breathe..."))
		breath_fail_ratio = clamp(0, (1 - inhale_efficiency + breath_fail_ratio)/2, 1)
		failed_inhale = 1
	else
		if(breath_fail_ratio && prob(20))
			to_chat(owner, SPAN_NOTICE("It gets easier to breathe."))
		breath_fail_ratio = clamp(0,breath_fail_ratio-0.05,1)

	owner.oxygen_alert = failed_inhale * 2

	var/inhaled_gas_used = (inhaling / 4) * (owner.species?.breath_eff_mul || 1)
	breath.adjust_gas(breath_type, -inhaled_gas_used, update = 0) //update afterwards

	owner.phoron_alert = 0
	if(!failed_inhale) // Enough gas to tell we're being poisoned via chemical burns or whatever.
		var/poison_total = 0
		if(poison_type) //TODO: Make this a list, other gasses besides phoron are deadly to humans
			for(var/gname as anything in breath.gas)
				if(gname == poison_type)
					poison_total += breath.gas[gname]
		if(((poison_total / breath.total_moles) * breath_pressure) > safe_toxins_max)
			owner.phoron_alert = 1

	// Pass reagents from the gas into our body.
	// Presumably if you breathe it you have a specialized metabolism for it, so we drop/ignore breath_type. Also avoids
	// humans processing thousands of units of oxygen over the course of a round.
	var/ratio = BP_IS_ROBOTIC(src)? 0.66 : 1
	for(var/gasname in breath.gas - breath_type)
		var/breathed_product = gas_data.breathed_product[gasname]
		if(!breathed_product)
			continue
		var/reagent_amount = breath.gas[gasname] * REAGENT_GAS_EXCHANGE_FACTOR * ratio
		if(reagent_amount < MINIMUM_CHEMICAL_VOLUME)
			continue
		owner.reagents.add_reagent(breathed_product, reagent_amount)
		breath.adjust_gas(gasname, -breath.gas[gasname], update = 0) //update after

	if(exhale_type && (!istype(owner.wear_mask) || !(exhale_type in owner.wear_mask.filtered_gases)))
		breath.adjust_gas_temp(exhale_type, inhaled_gas_used, owner.bodytemperature, update = 0) //update afterwards

	// Were we able to breathe?
	var/failed_breath = failed_inhale || failed_exhale
	if(!failed_breath)
		last_successful_breath = world.time
		if(owner.disabilities & ASTHMA)
			owner.adjustOxyLoss(rand(-5,0) * inhale_efficiency)
		else
			owner.adjustOxyLoss(-5 * inhale_efficiency)
		if(!BP_IS_ROBOTIC(src) && species.breathing_sound && is_below_sound_pressure(get_turf(owner)))
			if(breathing || owner.shock_stage >= 10)
				sound_to(owner, sound(species.breathing_sound,0,0,0,5))
				breathing = 0
			else
				breathing = 1

	// Hot air hurts :(
	handle_temperature_effects(breath)
	breath.update_values()

	if(failed_breath)
		handle_failed_breath()
	else
		owner.oxygen_alert = 0
	return failed_breath

/obj/item/organ/internal/lungs/proc/handle_temperature_effects(datum/gas_mixture/breath)
	if((breath.temperature < species.cold_level_1 || breath.temperature > species.heat_level_1) && !(owner.mutations & COLD_RESISTANCE))
		var/breath_damage
		if(breath.temperature < owner.species.cold_level_1)
			if(prob(20))
				to_chat(owner, SPAN_DANGER("You feel your face freezing and icicles forming in your lungs!"))
			if(breath.temperature < owner.species.cold_level_3)
				breath_damage = COLD_GAS_DAMAGE_LEVEL_3
			else if (breath.temperature < species.cold_level_2)
				breath_damage = COLD_GAS_DAMAGE_LEVEL_2
			else
				breath_damage = COLD_GAS_DAMAGE_LEVEL_1
			if(prob(20))
				owner.apply_damage(breath_damage, DAMAGE_BURN, BP_HEAD, used_weapon = "Excessive Cold")
			else
				damage += breath_damage
			owner.fire_alert = 1

		else if(breath.temperature > owner.species.heat_level_1)
			if(prob(20))
				to_chat(owner, SPAN_DANGER("You feel your face burning and a searing heat in your lungs!"))
			if(breath.temperature > owner.species.heat_level_3)
				breath_damage = HEAT_GAS_DAMAGE_LEVEL_3
			else if (breath.temperature > species.heat_level_2)
				breath_damage = HEAT_GAS_DAMAGE_LEVEL_2
			else
				breath_damage = HEAT_GAS_DAMAGE_LEVEL_1
			if(prob(20))
				owner.apply_damage(breath_damage, DAMAGE_BURN, BP_HEAD, used_weapon = "Excessive Heat")
			else
				damage += breath_damage
			owner.fire_alert = 2

		//breathing in hot/cold air also heats/cools you a bit
		var/temp_adj = breath.temperature - owner.bodytemperature
		if(temp_adj)
			if (temp_adj < 0)
				temp_adj /= (BODYTEMP_COLD_DIVISOR * 5)	//don't raise temperature as much as if we were directly exposed
			else
				temp_adj /= (BODYTEMP_HEAT_DIVISOR * 5)	//don't raise temperature as much as if we were directly exposed

			temp_adj *= breath.total_moles / (MOLES_CELLSTANDARD * BREATH_PERCENTAGE)

			owner.bodytemperature += clamp(temp_adj, BODYTEMP_COOLING_MAX, BODYTEMP_HEATING_MAX)

	else if(owner.bodytemperature >= owner.species.heat_discomfort_level)
		owner.species.get_environment_discomfort(owner,"heat")
	else if(owner.bodytemperature <= owner.species.cold_discomfort_level)
		owner.species.get_environment_discomfort(owner,"cold")

/obj/item/organ/internal/lungs/listen()
	if(owner.failed_last_breath)
		return "no respiration"

	if(owner.status_flags & FAKEDEATH)
		return "no respiration"

	if(BP_IS_ROBOTIC(src))
		if(is_bruised())
			return "malfunctioning fans"
		else
			return "air flowing"

	. = list()
	if(is_bruised())
		. += "[pick("wheezing", "gurgling")] sounds"
	if(rescued)
		. += "a whistling sound"

	var/list/breathtype = list()
	if(get_oxygen_deprivation() > 50)
		breathtype += pick("straining","labored")
	if(owner.shock_stage > 50)
		breathtype += pick("shallow and rapid")
	if(!breathtype.len)
		breathtype += "healthy"

	. += "[english_list(breathtype)] breathing"

	return english_list(.)

/obj/item/organ/internal/lungs/special_condition()
	return rescued

/obj/item/organ/internal/lungs/surgical_fix(mob/user)
	..()
	rescued = FALSE

#undef HUMAN_MAX_OXYLOSS
#undef REAGENT_GAS_EXCHANGE_FACTOR
