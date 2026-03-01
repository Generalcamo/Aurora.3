//Light's Edge sectors
/datum/space_sector/lights_edge//Uses the Weeping Stars attributes since it's neighboring and this is not exactly the void just yet
	name = SECTOR_LIGHTS_EDGE
	description = "An unusual region which is sparsely populated even in the 25th century, Light’s Edge was the furthest extent of the Alliance’s hegemonic era exploration efforts in the southeastern Spur. Few attempts were made to colonize it prior to the Interstellar War and even fewer of these attempts were successful, with Assunzione being the most successful of all hegemonic era colonies in the region. Light’s Edge derives its name from its position next to Lemurian Sea, a vast and mostly uncharted region which is entirely devoid of stars. Both Light’s Edge and the Lemurian Sea are home to a variety of unusual stellar phenomena which have attracted widespread scientific interest."
	skybox_icon = "weeping_stars"
	starlight_color = "#615bff"
	starlight_power = 1//slightly darker though for spooky factor
	starlight_range = 2

	lobby_tracks = list(
		'sound/music/lobby/lights_edge/lights_edge_1.ogg',
		'sound/music/lobby/lights_edge/lights_edge_2.ogg'
	)

/datum/space_sector/lights_edge/assunzione
	name = SECTOR_AL_MAQDISI
	description = "The furthest system colonized in the peak of the Sol Alliance's colonization frenzy, disaster struck when the sun unexpectedly went out. Despite this, the colony on Assunzione thrived."
	starlight_range = 1//There is no sun
	ports_of_call = list("the capital city of Triesto", "the city of Iraklio", "the city of Said")
	scheduled_port_visits = list("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday") // Every day of the week, the Horizon is here to recuperate
	//guaranteed_exoplanets = list() Add Assunzione when it's made

/datum/space_sector/lemurian_sea//The actual proposed area of void as written. Should be as dark as possible, due to no starlight
	name = SECTOR_LEMURIAN_SEA
	description = "The Lemurian Sea is an astrological curiosity which is entirely free of stars. This region is a relatively new discovery and classification, having only been officially broken off of Light’s Edge by most astrographical institutions following the rediscovery of Assunzione and limited exploration beyond its position on the border of what would become the Lemurian Sea. Most astrological charts advise avoiding the region as travelers are known to report a feeling of general uneasiness while passing through it and many vessels are known to have disappeared within the Sea. "
	skybox_icon = "void"//its just black
	possible_exoplanets = null//nothing should be here
	starlight_color = "#000000"
	starlight_power = 0
	starlight_range = 0

	lobby_tracks = list(
		'sound/music/lobby/lights_edge/lights_edge_1.ogg',
		'sound/music/lobby/lights_edge/lights_edge_2.ogg',
		'sound/music/lobby/dangerous_space/dangerous_space_1.ogg'
	)

/datum/space_sector/lemurian_sea/far
	name = SECTOR_LEMURIAN_SEA_FAR
	ccia_link = FALSE
