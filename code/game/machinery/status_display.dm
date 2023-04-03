#define FONT_COLOR "#09f"
#define FONT_STYLE "5pt 'Small Fonts'"
#define SCROLL_SPEED 2
#define LINE1_Y -8
#define LINE2_Y -15

// Status display
// (formerly Countdown timer display)

// Use to show shuttle ETA/ETD times
// Alert status
// And arbitrary messages set by comms computer
/obj/machinery/status_display
	name = "status display"
	desc = null
	icon = 'icons/obj/status_display.dmi'
	icon_state = "frame"
	layer = OBJ_LAYER
	anchored = 1
	density = FALSE
	use_power = POWER_USE_IDLE
	idle_power_usage = 10
	obj_flags = OBJ_FLAG_MOVES_UNSUPPORTED
	var/hears_arrivals = FALSE
	var/mode = SD_BLANK

	maptext_height = 26
	maptext_width = 32
	maptext_y = -1

	var/picture_state	// icon_state of alert picture
	var/message1 = ""	// message line 1
	var/message2 = ""	// message line 2
	var/index1			// display index for scrolling messages or 0 if non-scrolling
	var/index2

	var/frequency = 1435		// radio frequency

	var/friendc = 0      // track if Friend Computer mode
	var/ignore_friendc = 0

	var/const/SD_BLANK = 0
	var/const/SD_SHUTTLE_TIMER = 1
	var/const/SD_MESSAGE = 2
	var/const/SD_ALERT = 3
	var/const/SD_TIME = 4
	var/const/SD_IMAGE = 5
	var/const/SD_CUSTOM = 99

	var/const/CHARS_PER_LINE = 5

	var/status_display_show_alert_border = FALSE

	var/seclevel

	var/global/list/screen_overlays

/obj/machinery/status_display/Destroy()
	SSmachinery.all_status_displays -= src
	SSradio.remove_object(src,frequency)
	return ..()

// register for radio system
/obj/machinery/status_display/Initialize()
	. = ..()
	SSmachinery.all_status_displays += src
	generate_overlays()
	if (hears_arrivals)
		SSradio.add_object(src, frequency, RADIO_ARRIVALS)
	else
		SSradio.add_object(src, frequency)

// timed process
/obj/machinery/status_display/process()
	if(stat & NOPOWER)
		remove_display()
		return

	update()

/obj/machinery/status_display/emp_act(severity)
	if(stat & (BROKEN|NOPOWER))
		..(severity)
		return
	set_picture(screen_overlays["ai_bsod"])
	..(severity)

/obj/machinery/status_display/proc/generate_overlays(force = FALSE)
	if(LAZYLEN(screen_overlays) && !force)
		return
	LAZYINITLIST(screen_overlays)
	screen_overlays["default"] = make_screen_overlay(icon, "default")
	screen_overlays["alert_blue"] = make_screen_overlay(icon, "alert_blue")
	screen_overlays["alert_yellow"] = make_screen_overlay(icon, "alert_yellow")
	screen_overlays["alert_red"] = make_screen_overlay(icon, "alert_red")
	screen_overlays["alert_delta"] = make_screen_overlay(icon, "alert_delta")
	screen_overlays["biohazard"] = make_screen_overlay(icon, "biohazard")
	screen_overlays["lockdown"] = make_screen_overlay(icon, "lockdown")
	screen_overlays["eva_ban"] = make_screen_overlay(icon, "eva_ban")
	screen_overlays["internals"] = make_screen_overlay(icon, "internals")
	screen_overlays["evacuation"] = make_screen_overlay(icon, "evacation")
	screen_overlays["medical"] = make_screen_overlay(icon, "medical")
	screen_overlays["ai_bsod"] = make_screen_overlay(icon, "ai_bsod")
	screen_overlays["ai_friend"] = make_screen_overlay(icon, "ai_friend")
	screen_overlays["outline"] = make_screen_overlay(icon, "outline")
	screen_overlays["alert_border_"] = make_screen_overlay(icon, "alert_border_")
	screen_overlays["alert_border_blue"] = make_screen_overlay(icon, "alert_border_blue")
	screen_overlays["alert_border_yellow"] = make_screen_overlay(icon, "alert_border_yellow")
	screen_overlays["alert_border_red"] = make_screen_overlay(icon, "alert_border_red")
	screen_overlays["alert_border_delta"] = make_screen_overlay(icon, "alert_border_delta")

// set what is displayed
/obj/machinery/status_display/proc/update()
	remove_display()
	if(friendc && !ignore_friendc)
		set_picture(screen_overlays["ai_friend"])
		if(status_display_show_alert_border)
			add_alert_border_to_display()
		return 1

	switch(mode)
		if(SD_BLANK)
			if (status_display_show_alert_border)
				add_alert_border_to_display()
			remove_display()
			set_light(0)
			return 1
		if(SD_SHUTTLE_TIMER)				//emergency shuttle timer
			if(evacuation_controller)
				if(evacuation_controller.is_prepared())
					message1 = "-ETD-"
					if (evacuation_controller.waiting_to_leave())
						message2 = "Launch"
					else
						message2 = get_shuttle_timer()
						if(length(message2) > CHARS_PER_LINE)
							message2 = "Error"
					update_display(message1, message2)
				else if(evacuation_controller.has_eta())
					message1 = "-ETA-"
					message2 = get_shuttle_timer()
					if(length(message2) > CHARS_PER_LINE)
						message2 = "Error"
					update_display(message1, message2)
				if (status_display_show_alert_border)
					add_alert_border_to_display()
				return 1
		if(SD_MESSAGE)
			var/line1
			var/line2

			if(!index1)
				line1 = message1
			else
				line1 = copytext_char(message1+"|"+message1, index1, index1+CHARS_PER_LINE)
				var/message1_len = length_char(message1)
				index1 += SCROLL_SPEED
				if(index1 > message1_len + 1)
					index1 -= (message1_len + 1)

			if(!index2)
				line2 = message2
			else
				line2 = copytext_char(message2+"|"+message2, index2, index2+CHARS_PER_LINE)
				var/message2_len = length_char(message2)
				index2 += SCROLL_SPEED
				if(index2 > message2_len + 1)
					index2 -= (message2_len + 1)
			update_display(line1, line2)
			if (status_display_show_alert_border)
				add_alert_border_to_display()
			return 1
		if(SD_ALERT)
			display_alert()
			if (status_display_show_alert_border)
				add_alert_border_to_display()
			return 1
		if(SD_IMAGE)
			if (status_display_show_alert_border)
				add_alert_border_to_display()
			set_picture(picture_state)
			return 1
		if(SD_TIME)
			message1 = "TIME"
			message2 = worldtime2text()
			update_display(message1, message2)
			if (status_display_show_alert_border)
				add_alert_border_to_display()
			return 1
	return 0

/obj/machinery/status_display/examine(mob/user)
	. = ..(user)
	if(mode != SD_BLANK && mode != SD_ALERT && mode != SD_IMAGE)
		to_chat(user, "The display says:<br>\t[sanitize(message1)]<br>\t[sanitize(message2)]")
	if(mode == SD_ALERT || status_display_show_alert_border)
		to_chat(user, "The current alert level is [get_security_level()].")

/obj/machinery/status_display/proc/set_messages(m1, m2)
	if(m1)
		index1 = (length_char(m1) > CHARS_PER_LINE)
		message1 = m1
	else
		message1 = ""
		index1 = 0

	if(m2)
		index2 = (length_char(m2) > CHARS_PER_LINE)
		message2 = m2
	else
		message2 = ""
		index2 = 0

/obj/machinery/status_display/proc/toggle_alert_border()
	status_display_show_alert_border = !status_display_show_alert_border

/obj/machinery/status_display/proc/add_alert_border_to_display()
	seclevel = get_security_level()
	add_overlay(screen_overlays["alert_border_[seclevel]"])

/obj/machinery/status_display/proc/display_alert()
	remove_display()

	add_overlay(overlay_image("background", layer + 0.01))

	seclevel = get_security_level()
	add_overlay(screen_overlays["alert_[seclevel]"])


/obj/machinery/status_display/proc/set_picture(state)
	remove_display()
	picture_state = state
	add_overlay(overlay_image("background", layer + 0.01))
	add_overlay(picture_state)
	set_light(1, 2, COLOR_WHITE)

/obj/machinery/status_display/proc/update_display(line1, line2)
	line1 = uppertext(line1)
	line2 = uppertext(line2)
	var/new_text = {"<div style="color:[FONT_COLOR];font:[FONT_STYLE];text-align:center;" valign="top">[line1]<br>[line2]</div>"}
	if(maptext != new_text)
		maptext = new_text
	set_light(1, 2, FONT_COLOR)

/obj/machinery/status_display/proc/get_shuttle_timer()
	var/timeleft = evacuation_controller.get_eta()
	if(timeleft < 0)
		return ""
	return "[add_zero(num2text((timeleft / 60) % 60),2)]:[add_zero(num2text(timeleft % 60), 2)]"

/obj/machinery/status_display/proc/get_supply_shuttle_timer()
	var/datum/shuttle/autodock/ferry/supply/shuttle = SScargo.shuttle
	if (!shuttle)
		return "Error"

	if(shuttle.has_arrive_time())
		var/timeleft = round((shuttle.arrive_time - world.time) / 10,1)
		if(timeleft < 0)
			return "Late"
		return "[add_zero(num2text((timeleft / 60) % 60),2)]:[add_zero(num2text(timeleft % 60), 2)]"
	return ""

/obj/machinery/status_display/proc/get_arrivals_shuttle_timer()
	var/datum/shuttle/autodock/ferry/arrival/shuttle = SSarrivals.shuttle
	if (!shuttle)
		return "Error"

	if(shuttle.has_arrive_time())
		var/timeleft = round((shuttle.arrive_time - world.time) / 10,1)
		if(timeleft < 0)
			return ""
		return "[add_zero(num2text((timeleft / 60) % 60),2)]:[add_zero(num2text(timeleft % 60), 2)]"
	return ""

/obj/machinery/status_display/proc/get_arrivals_shuttle_timer2()
	if (!SSarrivals)
		return "Error"

	if(SSarrivals.launch_time)
		var/timeleft = round((SSarrivals.launch_time - world.time) / 10,1)
		if(timeleft < 0)
			return ""
		return "[add_zero(num2text((timeleft / 60) % 60),2)]:[add_zero(num2text(timeleft % 60), 2)]"
	else
		return "Launch"

/obj/machinery/status_display/proc/remove_display()
	cut_overlays()
	if(maptext)
		maptext = ""
	set_light(0)

/obj/machinery/status_display/receive_signal(datum/signal/signal)
	switch(signal.data["command"])
		if("blank")
			mode = SD_BLANK

		if("shuttle")
			mode = SD_SHUTTLE_TIMER

		if("message")
			mode = SD_MESSAGE
			set_messages(signal.data["msg1"], signal.data["msg2"])

		if("alert")
			mode = SD_ALERT

		if("time")
			mode = SD_TIME

		if("image")
			mode = SD_IMAGE
			set_picture(screen_overlays[signal.data["picture_state"]])

		if("toggle_alert_border")
			toggle_alert_border()

	update()

#undef FONT_COLOR
#undef FONT_STYLE
#undef SCROLL_SPEED
