/obj/machinery/Value()
	. = ..()
	if(is_broken())
		. *= 0.5
	. = round(.)
