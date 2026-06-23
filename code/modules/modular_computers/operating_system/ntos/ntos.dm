/datum/operating_system/default/ntos
	name = "Nanotrasen Operating System"

	description = "A sleek and modern operating system developed by Nanotrasen for use on their modular computer systems."

	///Static list of default programs that come with ALL computers, here so computers don't have to repeat this.
	var/static/list/datum/computer_file/default_programs = list(
		/datum/computer_file/program/themeify,
		/datum/computer_file/program/ntnetdownload,
		/datum/computer_file/program/filemanager,
	)

	///Non-static list of programs the computer should receive on Initialize.
	var/list/datum/computer_file/starting_programs = list()

	///Idle programs on background. They still receive process calls but can't be interacted with.
	var/list/datum/computer_file/program/idle_threads = list()

	/// Amount of programs that can be ran at once
	var/max_idle_programs = 2

/datum/operating_system/default/ntos/install(mob/user)
	..()
	for(var/programs in default_programs + starting_programs)
		var/datum/computer_file/program_type = new programs
		store_file(program_type)

/datum/operating_system/default/ntos/run_program(mob/user, program)
	..()

/datum/operating_system/default/ntos/kill_program(mob/user, program)
	..()
	for(var/datum/computer_file/program/idle as anything in idle_threads)
		if(idle.name == program)
			idle.kill_program()


/datum/operating_system/default/ntos/proc/find_file_by_name(filename)
	if(!istext(filename))
		return null

	for(var/datum/computer_file/file as anything in target_disk.stored_files)
		if(file.filename == filename)
			return file
	return null

/datum/operating_system/default/ntos/ui_assets(mob/user)
	return get_asset_datum(/datum/asset/simple/headers)

/datum/operating_system/default/ntos/ui_act(mob/user)
	. = ..()
	if(.)
		return

/datum/operating_system/default/ntos/ui_data(mob/user)
	var/data = list()

	data["PC_device_theme"] = device_theme

	if(internal_cell)
		data["PC_lowpower_mode"] = !internal_cell.charge
		switch(internal_cell.percent())
			if(80 to INFINITY)
				data["PC_batteryicon"] = "batt_100.gif"
			if(60 to 80)
				data["PC_batteryicon"] = "batt_80.gif"
			if(40 to 60)
				data["PC_batteryicon"] = "batt_60.gif"
			if(20 to 40)
				data["PC_batteryicon"] = "batt_40.gif"
			if(5 to 20)
				data["PC_batteryicon"] = "batt_20.gif"
			else
				data["PC_batteryicon"] = "batt_5.gif"
		data["PC_batterypercent"] = "[round(internal_cell.percent())]%"
	else
		data["PC_lowpower_mode"] = FALSE
		data["PC_batteryicon"] = null
		data["PC_batterypercent"] = null

	switch(get_ntnet_status())
		if(NTNET_NO_SIGNAL)
			data["PC_ntneticon"] = "sig_none.gif"
		if(NTNET_LOW_SIGNAL)
			data["PC_ntneticon"] = "sig_low.gif"
		if(NTNET_GOOD_SIGNAL)
			data["PC_ntneticon"] = "sig_high.gif"
		if(NTNET_ETHERNET_SIGNAL)
			data["PC_ntneticon"] = "sig_lan.gif"

	var/list/program_headers = list()
	if(length(idle_threads))
		for(var/datum/computer_file/program/idle_programs as anything in idle_threads)
			if(!idle_programs.ui_header)
				continue
			program_headers.Add(list(list("icon" = idle_programs.ui_header)))

	data["PC_programheaders"] = program_headers

	data["PC_stationtime"] = station_time_timestamp()
	data["PC_stationdate"] = "[time2text(world.realtime, "DDD, Month DD", NO_TIMEZONE)], [CURRENT_STATION_YEAR]"
	data["PC_showexitprogram"] = !!active_program // Hides "Exit Program" button on mainscreen


	data["programs"] = list()
	for(var/datum/computer_file/program/program in stored_files)
		data["programs"] += list(list(
			"name" = program.filename,
			"desc" = program.filedesc,
			"header_program" = !!(program.program_flags & PROGRAM_HEADER),
			"running" = !!(program in idle_threads),
			"icon" = program.program_icon,
			"alert" = program.alert_pending,
		))


	data["pai"] = inserted_pai
	data["has_light"] = has_light
	data["light_on"] = light_on
	data["comp_light_color"] = comp_light_color

	data["login"] = list(
		IDName = saved_identification || "Unknown",
		IDJob = saved_job || "Unknown",
	)

	data["proposed_login"] = list(
		IDInserted = operating_computer.stored_id ? TRUE : FALSE,
		IDName = operating_computer.stored_id?.registered_name,
		IDJob = operating_computer.stored_id?.assignment,
	)

	data["removable_media"] = list()
	if(inserted_disk)
		data["removable_media"] += "Eject Disk"
	var/datum/computer_file/program/ai_restorer/airestore_app = locate() in stored_files
	if(airestore_app?.stored_card)
		data["removable_media"] += "intelliCard"

	data["alert_style"] = operating_computer.get_security_level_relevancy()
	data["alert_color"] = SSsecurity_level?.current_security_level?.announcement_color
	data["alert_name"] = SSsecurity_level?.current_security_level?.name_shortform
	return data
/*
/datum/operating_system/default/ntos/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(ishuman(usr) && !allow_chunky)
		var/mob/living/carbon/human/human_user = usr
		if(human_user.check_chunky_fingers())
			balloon_alert(human_user, "fingers are too big!")
			return TRUE

	switch(action)
		if("PC_exit")
			//you can't close apps in emergency mode.
			if(isnull(internal_cell) || internal_cell.charge)
				active_program.kill_program(usr)
			return TRUE
		if("PC_shutdown")
			shutdown_computer()
			return TRUE
		if("PC_minimize")
			if(!active_program || (!isnull(internal_cell) && !internal_cell.charge))
				return
			active_program.background_program(usr)
			return TRUE

		if("PC_killprogram")
			var/prog = params["name"]
			var/datum/computer_file/program/killed_program = find_file_by_name(prog)

			if(!istype(killed_program))
				return

			killed_program.kill_program(usr)
			to_chat(usr, span_notice("Program [killed_program.filename].[killed_program.filetype] with PID [rand(100,999)] has been killed."))
			return TRUE

		if("PC_runprogram")
			open_program(usr, find_file_by_name(params["name"]))
			return TRUE

		if("PC_toggle_light")
			toggle_flashlight()
			return TRUE

		if("PC_light_color")
			var/mob/user = usr
			var/new_color
			while(!new_color)
				new_color = input(user, "Choose a new color for [src]'s flashlight.", "Light Color",light_color) as color|null
				if(!new_color)
					return
				if(is_color_dark(new_color, 50) ) //Colors too dark are rejected
					to_chat(user, span_warning("That color is too dark! Choose a lighter one."))
					new_color = null
			set_flashlight_color(new_color)
			return TRUE

		if("PC_Eject_Disk")
			var/param = params["name"]
			var/mob/user = usr
			switch(param)
				if("Eject Disk")
					if(!inserted_disk)
						return

					if(!user || !Adjacent(user))
						inserted_disk.forceMove(drop_location())
					else
						user.put_in_hands(inserted_disk)
					inserted_disk = null
					playsound(src, 'sound/machines/card_slide.ogg', 50)
					return TRUE

				if("intelliCard")
					var/datum/computer_file/program/ai_restorer/airestore_app = locate() in stored_files
					if(!airestore_app)
						return

					if(airestore_app.try_eject(user))
						playsound(src, 'sound/machines/card_slide.ogg', 50)
						return TRUE

				if("ID")
					if(remove_id(user))
						playsound(src, 'sound/machines/card_slide.ogg', 50)
						return TRUE

		if("PC_Imprint_ID")
			imprint_id()
			UpdateDisplay()
			playsound(src, 'sound/machines/terminal/terminal_processing.ogg', 15, TRUE)

		if("PC_Pai_Interact")
			switch(params["option"])
				if("eject")
					if(!ishuman(usr))
						return
					remove_pai(usr)
				if("interact")
					inserted_pai.attack_self(usr)
			return TRUE

	if(active_program)
		return active_program.ui_act(action, params, ui, state)
*/
