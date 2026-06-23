/datum/operating_system/ntos/mobile
	name = "NTOS Mobile"
	description = "A streamlined version of NTOS designed for mobile modular computers."

	///The program currently active on the tablet.
	var/datum/computer_file/program/active_program

	var/ntos_theme = PDA_THEME_NTOS


/datum/operating_system/ntos/mobile/interact(mob/user)
	ui = SStgui.try_update_ui(user, src, null)
	if(!ui)
		ui = new(user, src, "NtosMain")
		ui.open()

/datum/operating_system/ntos/mobile/ui_data(mob/user)
	. = ..()
	if(active_program)
		. += active_program.ui_data(user)

/datum/operating_system/default/ntos/mobile/run_program(mob/user, programName)
	var/datum/computer_file/program/program = find_file_by_name(programName)
	if(program.computer != operating_computer)
		CRASH("tried to open program that does not belong to this computer")

	if(isnull(program) || !istype(program)) // Program not found or it's not executable program.
		if(user)
			to_chat(user, span_danger("\The [operating_computer]'s screen shows \"I/O ERROR - Unable to run program\" warning."))
		return FALSE

	if(active_program == program)
		return FALSE

	// The program is already running. Resume it.
	if(program in idle_threads)
		active_program?.background_program()
		active_program = program
		program.alert_pending = FALSE
		idle_threads.Remove(program)
		operating_computer.update_appearance(UPDATE_ICON)
		return TRUE

	if(!program.is_supported_by_hardware(operating_computer.hardware_flag, loud = TRUE, user = user))
		return FALSE

	if(idle_threads.len > max_idle_programs)
		if(user)
			to_chat(user, span_danger("\The [operating_computer] displays a \"Maximal CPU load reached. Unable to run another program.\" error."))
		return FALSE

	if(program.program_flags & PROGRAM_REQUIRES_NTNET && !operating_computer.get_ntnet_status()) // The program requires NTNet connection, but we are not connected to NTNet.
		if(user)
			to_chat(user, span_danger("\The [operating_computer]'s screen shows \"Unable to connect to NTNet. Please retry. If problem persists contact your system administrator.\" warning."))
		return FALSE

	if(!program.on_start(user))
		return FALSE

	active_program?.background_program()

	active_program = program
	program.alert_pending = FALSE
	operating_computer.update_appearance(UPDATE_ICON)
	return TRUE

/datum/operating_system/default/ntos/mobile/kill_program(mob/user, program)
	..()
	if(active_program && active_program.name == program)
		active_program?.kill_program()

/datum/operating_system/default/ntos/mobile/ui_assets(mob/user)
	. = ..()
	if(active_program)
		. += active_program.ui_assets(user)

/datum/operating_system/default/ntos/mobile/ui_static_data(mob/user)
	var/list/data = list()
	if(active_program)
		data += active_program.ui_static_data(user)
		return data

	data["show_imprint"] = TRUE
	return data

/datum/operating_system/default/ntos/mobile/ui_close(mob/user)
	. = ..()
	active_program?.ui_close(user)
