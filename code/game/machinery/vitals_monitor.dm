#define PULSE_ALERT 1
#define BRAIN_ALERT 2
#define LUNGS_ALERT 3

/obj/machinery/vitals_monitor
	name = "vitals monitor"
	desc = "A bulky yet mobile machine, showing some odd graphs."
	desc_mechanics = "This can be click-dragged to operating tables (or vice-versa) to show their occupant's vitals. It can also be click-dragged onto mobs (or vice-versa) to show their vitals, if they have any. It can be alt-clicked to turn on or off the sound, or alt-right-clicked to turn on or off the alert reader."
	desc_upgrade = "With at least 6 levels of scanning hardware installed, this vitals monitor can display detailed information about fractures and arterial bleeding."
	icon = 'icons/obj/machinery/heartmonitor.dmi'
	icon_state = "base"
	anchored = FALSE
	idle_power_usage = 10
	active_power_usage = 100

	component_types = list(
			/obj/item/circuitboard/vitals_monitor,
			/obj/item/stock_parts/scanning_module = 1
		)

	/// The person whose vitals are being monitored, if any
	var/mob/living/carbon/human/connected_person
	/// The operating table this vitals monitor is connected to, if any
	var/obj/machinery/optable/connected_optable = null

	var/beep = TRUE

	//alert stuff
	/// Read alerts aloud
	var/read_alerts = TRUE
	/// Cooldown time between alerts in ticks
	var/alert_cooldown = 5 SECONDS
	/// Time since last alert
	var/last_alert_time = 0
	/// Current alerts
	var/list/alerts = null
	/// Last alerts (for comparison)
	var/list/last_alert = null

	/// Does it give info on fractures and arterial?
	var/detailed = FALSE

	///The sound this vitals monitor will emit when flatlining
	var/flatline_looping_sound_type = /datum/looping_sound/flatline

	///The looping sound used during the flatline
	VAR_PRIVATE/datum/looping_sound/flatline_looping_sound

/obj/machinery/vitals_monitor/Initialize()
	. = ..()
	alerts = new(3)
	last_alert = new(3)
	flatline_looping_sound = new flatline_looping_sound_type(src)
	for (dir in list(NORTH,EAST,SOUTH,WEST))
		connected_optable = locate(/obj/machinery/optable, get_step(src, dir))
		if (connected_optable)
			connected_optable.connected_monitor = src
			break

/obj/machinery/vitals_monitor/Destroy()
	connected_person = null
	update_optable()
	if(flatline_looping_sound)
		flatline_looping_sound.stop(TRUE)
	QDEL_NULL(flatline_looping_sound)
	. = ..()

/obj/machinery/vitals_monitor/get_examine_text(mob/user, distance, is_adjacent, infix, suffix)
	. = ..()
	if (!powered())
		. += SPAN_NOTICE("It's unpowered.")
	if (!connected_optable)
		. += SPAN_WARNING("Its operating table interface is disconnected.")
	else
		. += SPAN_NOTICE("Its operating table interface is connected to \the [connected_optable.name].")
	if (!connected_person || !powered())
		. += SPAN_NOTICE("It is not displaying any information.")
		return
	else if (connected_person && !connected_optable)
		. += SPAN_NOTICE("It is directly connected to \the [connected_person.name].")
	. += ""
	. += span("scan_notice", "Vitals of \the [connected_person]:")

	var/brain_activity = "none"
	var/obj/item/organ/internal/brain/brain = connected_person.internal_organs_by_name[BP_BRAIN]
	var/danger = 0
	if (istype(brain) && connected_person.stat != DEAD && !(connected_person.status_flags & FAKEDEATH))
		//if (user.skill_check(SKILL_MEDICAL, SKILL_BASIC)) // Future skills
		switch (brain.get_current_damage_threshold())
			if (0)
				brain_activity = "normal"
			if (1 to 2)
				brain_activity = "minor brain damage"
				danger = 1
			if (3 to 5)
				brain_activity = "weak"
				danger = 1
			if (6 to 8)
				brain_activity = "extremely weak"
				danger = 2
			if (9 to INFINITY)
				brain_activity = "fading"
				danger = 2

		//else // Future skills
		//	brain_activity = "some"
	if (!danger)
		. += span("scan_notice", "Brain activity: [brain_activity]")
	else if (danger == 1)
		. += span("scan_warning", "Brain activity: [brain_activity]")
	else
		. += span("scan_danger", "Brain activity: [brain_activity]")

	. += span("scan_notice", "Pulse: [connected_person.get_pulse(GETPULSE_TOOL)]")
	var/additional_information = FALSE
	if(distance < 5 || is_adjacent)
		. += span("scan_notice", "Blood pressure: [connected_person.get_blood_pressure()]")
		. += span("scan_notice", "Blood oxygenation: [connected_person.get_blood_oxygenation()]%")
		. += span("scan_notice", "Body temperature: [connected_person.bodytemperature-T0C]&deg;C ([connected_person.bodytemperature*1.8-459.67]&deg;F)")
	else
		additional_information = TRUE

	var/breathing = "none"
	danger = 2
	var/obj/item/organ/internal/lungs/lungs = connected_person.internal_organs_by_name[BP_LUNGS]
	if (istype(lungs) && !(connected_person.status_flags & FAKEDEATH))
		if (lungs.breath_fail_ratio < 0.3)
			breathing = "normal"
			danger = 0
		else if (lungs.breath_fail_ratio < 1)
			breathing = "shallow"
			danger = 1

	if (!danger)
		. += span("scan_notice", "Breathing: [breathing]")
	else if (danger == 1)
		. += span("scan_warning", "Breathing: [breathing]")
	else
		. += span("scan_danger", "Breathing: [breathing]")

	if (additional_information)
		. += SPAN_NOTICE("You see some extra information, but you aren't close enough to make it out.")
		return

	//if (detailed && user.skill_check(SKILL_MEDICAL, SKILL_TRAINED)) // Future skills
	if (detailed)
		for (var/name in connected_person.organs_by_name)
			var/obj/item/organ/external/organ = connected_person.organs_by_name[name]
			if (!organ)
				continue
			var/limb = organ.name
			var/dat = null
			if (organ.status & ORGAN_BROKEN | ORGAN_ARTERY_CUT)
				dat += "[limb]: "
			if (organ.status & ORGAN_BROKEN)
				dat += span("scan_warning", "Bone fracture.")
			if (organ.status & ORGAN_ARTERY_CUT)
				dat += span("scan_warning", "Arterial bleeding.")
			if (dat)
				dat = capitalize(dat)
				. += SPAN_WARNING("[dat]")

/obj/machinery/vitals_monitor/process()
	if (QDELETED(connected_person))
		update_connected_person()
	if (connected_person && !Adjacent(connected_person))
		update_connected_person()
	if (connected_optable && !Adjacent(connected_optable))
		update_connected_person()
		update_optable()
	if (connected_person)
		update_icon()

/obj/machinery/vitals_monitor/proc/update_connected_person(new_connected_person = null)
	var/old_connected_person = connected_person
	connected_person = new_connected_person
	if (connected_person)
		visible_message(SPAN_NOTICE("\The [src] is now showing data for \the [connected_person]."))
	else
		if (old_connected_person != new_connected_person) // Protects against qdel edge case. In all other cases we want a message printed.
			visible_message(SPAN_NOTICE("\The [src] is no longer showing data from [isnull(old_connected_person)? "any patient" : "\the [old_connected_person]"]."))
	update_use_power(isnull(connected_person)? POWER_USE_IDLE : POWER_USE_ACTIVE)
	update_icon()

/obj/machinery/vitals_monitor/proc/update_optable(obj/machinery/optable/new_optable = null)
	if (new_optable == connected_optable)
		return
	if (connected_optable) //gotta clear existing connections first
		connected_optable.connected_monitor = null
	connected_optable = new_optable
	if (connected_optable)
		connected_optable.connected_monitor = src
		visible_message(SPAN_NOTICE("\The [src] is now relaying information from \the [connected_optable]"))
		//In case there's already a patient on the table
		update_connected_person(get_occupant())
	else
		visible_message(SPAN_NOTICE("\The [src] is no longer relaying data from a connected operating table."))

/obj/machinery/vitals_monitor/mouse_drop_receive(atom/dropped, mob/user, params)
	. = ..()
	if(use_check_and_message(user, USE_DISALLOW_SPECIALS))
		return
	update_optable()
	if (connected_person)
		update_connected_person()
	else if (ishuman(dropped))
		update_connected_person(dropped)
	else if (istype(dropped, /obj/machinery/optable))
		var/obj/machinery/optable/new_table_connection = dropped
		update_optable(new_table_connection)

/obj/machinery/vitals_monitor/mouse_drop_dragged(atom/over, mob/user, src_location, over_location, params)
	. = ..()
	if(use_check_and_message(user, USE_DISALLOW_SPECIALS))
		return
	update_optable()
	if (connected_person)
		update_connected_person()
	else if (ishuman(over))
		update_connected_person(over)
	else if (istype(over, /obj/machinery/optable))
		var/obj/machinery/optable/new_table_connection = over
		update_optable(new_table_connection)

/obj/machinery/vitals_monitor/update_icon()
	ClearOverlays()
	if (!powered())
		return
	AddOverlays(image(icon, icon_state = "screen"))

	handle_pulse()
	handle_brain()
	handle_lungs()
	handle_alerts()

/obj/machinery/vitals_monitor/proc/handle_pulse()
	if (!connected_person)
		return
	var/obj/item/organ/internal/heart/heart = connected_person.internal_organs_by_name[BP_HEART]
	if (istype(heart) && !BP_IS_ROBOTIC(heart))
		switch (connected_person.pulse())
			if (PULSE_NONE)
				AddOverlays(emissive_appearance(icon, "pulse_flatline"))
				AddOverlays(emissive_appearance(icon, "pulse_warning"))
				AddOverlays(image(icon, icon_state = "pulse_flatline"))
				AddOverlays(image(icon, icon_state = "pulse_warning"))
				if (beep)
					flatline_looping_sound.start()
				else
					flatline_looping_sound.stop()
				if (read_alerts)
					alerts[PULSE_ALERT] = "Cardiac flatline detected!"
			if (PULSE_SLOW, PULSE_NORM)
				flatline_looping_sound.stop()
				AddOverlays(emissive_appearance(icon, "pulse_normal"))
				AddOverlays(image(icon, icon_state = "pulse_normal"))
				if (beep)
					playsound(src, 'sound/machines/quiet_beep.ogg', 40)
			if (PULSE_FAST, PULSE_2FAST)
				flatline_looping_sound.stop()
				AddOverlays(emissive_appearance(icon, "pulse_veryfast"))
				AddOverlays(image(icon, icon_state = "pulse_veryfast"))
				if (beep)
					playsound(src, 'sound/machines/quiet_double_beep.ogg', 40)
			if (PULSE_THREADY)
				flatline_looping_sound.stop()
				AddOverlays(emissive_appearance(icon, "pulse_thready"))
				AddOverlays(image(icon, icon_state = "pulse_thready"))
				AddOverlays(emissive_appearance(icon, "pulse_warning"))
				AddOverlays(image(icon, icon_state = "pulse_warning"))
				if (beep)
					playsound(src, 'sound/machines/ekg_alert.ogg', 40)
				if (read_alerts)
					alerts[PULSE_ALERT] = "Excessive heartbeat! Possible Shock Detected!"
	else
		AddOverlays(emissive_appearance(icon, "pulse_warning"))
		AddOverlays(image(icon, icon_state = "pulse_warning"))

/obj/machinery/vitals_monitor/proc/handle_brain()
	if (!connected_person)
		return
	var/obj/item/organ/internal/brain/brain = connected_person.internal_organs_by_name[BP_BRAIN]
	if (istype(brain) && connected_person.stat != DEAD && !(connected_person.status_flags & FAKEDEATH))
		switch (brain.get_current_damage_threshold())
			if (0 to 2)
				AddOverlays(emissive_appearance(icon, "brain_ok"))
				AddOverlays(image(icon, icon_state = "brain_ok"))
			if (3 to 5)
				AddOverlays(emissive_appearance(icon, "brain_bad"))
				AddOverlays(image(icon, icon_state = "brain_bad"))
				if (read_alerts)
					alerts[BRAIN_ALERT] = "Weak brain activity!"
			if (6 to INFINITY)
				AddOverlays(emissive_appearance(icon, "brain_verybad"))
				AddOverlays(image(icon, icon_state = "brain_verybad"))
				AddOverlays(emissive_appearance(icon, "brain_warning"))
				AddOverlays(image(icon, icon_state = "brain_warning"))
				if (read_alerts)
					alerts[BRAIN_ALERT] = "Very weak brain activity!"
	else
		AddOverlays(emissive_appearance(icon, "brain_warning"))
		AddOverlays(image(icon, icon_state = "brain_warning"))

/obj/machinery/vitals_monitor/proc/handle_lungs()
	if (!connected_person)
		return
	var/obj/item/organ/internal/lungs/lungs = connected_person.internal_organs_by_name[BP_LUNGS]
	if (istype(lungs) && !(connected_person.status_flags & FAKEDEATH))
		if (lungs.breath_fail_ratio < 0.3)
			AddOverlays(emissive_appearance(icon, "breathing_normal"))
			AddOverlays(image(icon, icon_state = "breathing_normal"))
		else if (lungs.breath_fail_ratio < 1)
			AddOverlays(emissive_appearance(icon, "breathing_shallow"))
			AddOverlays(image(icon, icon_state = "breathing_shallow"))
			if (read_alerts)
				alerts[LUNGS_ALERT] = "Abnormal breathing detected!"
		else
			AddOverlays(emissive_appearance(icon, "breathing_warning"))
			AddOverlays(image(icon, icon_state = "breathing_warning"))
			if (read_alerts)
				alerts[LUNGS_ALERT] = "Patient is not breathing!"
	else
		AddOverlays(emissive_appearance(icon, "breathing_warning"))
		AddOverlays(image(icon, icon_state = "breathing_warning"))

/obj/machinery/vitals_monitor/proc/handle_alerts()
	if (!connected_person || !read_alerts) //Clear our alerts
		alerts[PULSE_ALERT] = ""
		alerts[BRAIN_ALERT] = ""
		alerts[LUNGS_ALERT] = ""
		return
	if (last_alert_time + alert_cooldown < world.time)
		if (alerts[PULSE_ALERT] && alerts[PULSE_ALERT] != last_alert[PULSE_ALERT])
			audible_message(SPAN_WARNING("<b>\The [src]</b> beeps, \"[alerts[PULSE_ALERT]]\""))
		if (alerts[BRAIN_ALERT] && alerts[BRAIN_ALERT] != last_alert[BRAIN_ALERT])
			audible_message(SPAN_WARNING("<b>\The [src]</b> alarms, \"[alerts[BRAIN_ALERT]]\""))
		if (alerts[LUNGS_ALERT] && alerts[LUNGS_ALERT] != last_alert[LUNGS_ALERT])
			audible_message(SPAN_WARNING("<b>\The [src]</b> warns, \"[alerts[LUNGS_ALERT]]\""))
		last_alert = alerts.Copy()
		last_alert_time = world.time



/obj/machinery/vitals_monitor/verb/toggle_beep()
	set name = "Toggle Monitor Beeping"
	set category = "Object"
	set src in view(1)

	var/mob/user = usr
	if (!istype(user))
		return

	toggle_sound()

/obj/machinery/vitals_monitor/AltClick(mob/user)
	. = ..()
	toggle_sound()

/obj/machinery/vitals_monitor/proc/toggle_sound()
	beep = !beep
	if(!beep)
		flatline_looping_sound.stop()
	playsound(src, /singleton/sound_category/button_sound, clickvol)
	balloon_alert_to_viewers("sound [beep ? "on" : "off"]")


/obj/machinery/vitals_monitor/verb/toggle_alerts()
	set name = "Toggle Alert Annunciator"
	set category = "Object"
	set src in view(1)

	var/mob/user = usr
	if (!istype(user))
		return

	toggle_alert()

/obj/machinery/vitals_monitor/click_alt_secondary(mob/user)
	. = ..()
	toggle_alert()

/obj/machinery/vitals_monitor/proc/toggle_alert()
	read_alerts = !read_alerts
	playsound(src, /singleton/sound_category/switch_sound, clickvol)
	balloon_alert_to_viewers("alerts [read_alerts ? "on" : "off"]")

/obj/item/circuitboard/vitals_monitor
	name = "circuit board (vitals monitor)"
	build_path = /obj/machinery/vitals_monitor
	board_type = BOARD_MACHINE
	req_components = list(
		/obj/item/stock_parts/console_screen = 1,
		/obj/item/stock_parts/scanning_module = 1)

/obj/machinery/vitals_monitor/RefreshParts()
	..()

	var/scanner_rating = 0

	for(var/obj/item/stock_parts/P in component_parts)
		if(isscanner(P))
			scanner_rating += P.rating

	if (scanner_rating >= 6)
		detailed = TRUE
	else
		detailed = FALSE

/obj/machinery/vitals_monitor/proc/get_occupant()
	if(connected_optable)

		if(istype(connected_optable.occupant, /datum/weakref))
			return connected_optable.occupant.resolve()
		else
			return connected_optable.occupant

	return null

#undef PULSE_ALERT
#undef BRAIN_ALERT
#undef LUNGS_ALERT
