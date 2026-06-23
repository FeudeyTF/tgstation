/**
 * update_tablet_open_uis
 *
 * Will search the user to see if they have the tablet open.
 * If they don't, we'll open a new UI depending on the tab the tablet is meant to be on.
 * If they do, we'll update the interface and title, then update all static data and re-send assets.
 *
 * This is best called when you're actually changing the app, as we don't check
 * if we're swapping to the current UI repeatedly.
 * Args:
 * user - The person whose UI we're updating. Only necessary if we're opening the UI for the first time.
 */
/obj/item/modular_computer/proc/update_tablet_open_uis(mob/user)
	to_chat(user, span_notice("Updating tablet UI..."))


/obj/item/modular_computer/ui_state(mob/user)
	if(inserted_pai && (user == inserted_pai.pai))
		return GLOB.contained_state
	return ..()

/obj/item/modular_computer/interact(mob/user)
	if(ishuman(user) && !allow_chunky)
		var/mob/living/carbon/human/human_user = user
		if(human_user.check_chunky_fingers())
			balloon_alert(human_user, "fingers are too big!")
			return TRUE
	if(enabled)
		ui_interact(user)
	else
		turn_on(user)

/obj/item/modular_computer/ui_interact(mob/user, datum/tgui/ui)
	if(!enabled || !user.can_read(src, READING_CHECK_LITERACY))
		ui?.close()
		return

	// Robots don't really need to see the screen, their wireless connection works as long as computer is on.
	if(!screen_on && !issilicon(user))
		ui?.close()
		return

	if(honkvirus_amount > 0) // EXTRA annoying, huh!
		honkvirus_amount--
		playsound(src, 'sound/items/bikehorn.ogg', 30, TRUE)

	if(!os)
		balloon_alert(user, "FATAL ERROR: NO OPERATING SYSTEM INSTALLED!")
		return

<<<<<<< HEAD
	os.interact(user)
=======
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
				new_color = tgui_color_picker(user, "Choose a new color for [src]'s flashlight.", "Light Color",light_color)
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

/obj/item/modular_computer/ui_host()
	if(physical)
		return physical
	return src

/obj/item/modular_computer/ui_close(mob/user)
	. = ..()
	if(active_program)
		active_program.ui_close(user)
>>>>>>> dba0b2d53db73e592394b1dd0c92299b7f6f8e5f
