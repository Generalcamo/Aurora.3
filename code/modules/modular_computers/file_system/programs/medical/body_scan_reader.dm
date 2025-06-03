/datum/computer_file/program/body_scan_reader
	filename = "bodyscanreader"
	filedesc = "Body Scan Reader"
	program_icon_state = "crew"
	program_key_icon_state = "teal_key"
	extended_desc = "This program reads out body scans pushed to the network by body scanners."
	required_access_run = ACCESS_MEDICAL
	required_access_download = ACCESS_MEDICAL
	requires_ntnet = FALSE
	network_destination = "medical scan storage system"
	size = 11
	usage_flags = PROGRAM_CONSOLE | PROGRAM_LAPTOP | PROGRAM_STATIONBOUND | PROGRAM_TELESCREEN
	color = LIGHT_COLOR_CYAN
	tgui_id = "SuitSensors"
	tgui_theme = "zenghu"
