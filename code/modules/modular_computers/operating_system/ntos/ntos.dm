/datum/operating_system/sosix/ntos
	name = "Nanotrasen Operating System"

	description = "A modern operating system developed by Nanotrasen for use on their modular computer systems."

	///Static list of default programs that come with ALL computers, here so computers don't have to repeat this.
	var/static/list/datum/computer_file/default_programs = list(
		/datum/computer_file/program/themeify,
		/datum/computer_file/program/ntnetdownload,
		/datum/computer_file/program/filemanager,
	)

	///Non-static list of programs the computer should receive on Initialize.
	var/list/datum/computer_file/starting_programs = list()

	///The theme, used for the main menu and file browser apps.
	var/device_theme = PDA_THEME_NTOS


/datum/operating_system/sosix/ntos/shutdown_os()
	..()
	for(var/datum/computer_file/program/idle as anything in idle_threads)
		kill_program(idle)

/datum/operating_system/sosix/ntos/install(mob/user)
	..()
	for(var/programs in default_programs + starting_programs)
		var/datum/computer_file/program_type = new programs
		store_file(program_type)

/datum/operating_system/sosix/ntos/run_program(mob/user, datum/computer_file/program/program, open_ui = TRUE)
	..()
	if(program.computer != hardware)
		CRASH("tried to open program that does not belong to this computer")

	if(isnull(program) || !istype(program)) // Program not found or it's not executable program.
		if(user)
			to_chat(user, span_danger("\The [hardware]'s screen shows \"I/O ERROR - Unable to run program\" warning."))
		return FALSE

	// The program is already running. Resume it.
	if(program in idle_threads)
		activate_program(program)
		program.alert_pending = FALSE
		idle_threads.Remove(program)
		if(open_ui)
			INVOKE_ASYNC(hardware, TYPE_PROC_REF(/obj/item/modular_computer, update_tablet_open_uis), user)
		hardware.update_appearance(UPDATE_ICON)
		return TRUE

	if(!program.is_supported_by_hardware(hardware.hardware_flag, loud = TRUE, user = user))
		return FALSE

	if(idle_threads.len > max_idle_programs)
		if(user)
			to_chat(user, span_danger("\The [hardware] displays a \"Maximal CPU load reached. Unable to run another program.\" error."))
		return FALSE

	if(program.program_flags & PROGRAM_REQUIRES_NTNET && !hardware.get_ntnet_status()) // The program requires NTNet connection, but we are not connected to NTNet.
		if(user)
			to_chat(user, span_danger("\The [hardware]'s screen shows \"Unable to connect to NTNet. Please retry. If problem persists contact your system administrator.\" warning."))
		return FALSE

	if(!program.on_start(user))
		return FALSE

	activate_program(program)
	program.alert_pending = FALSE
	if(open_ui)
		INVOKE_ASYNC(hardware, TYPE_PROC_REF(/obj/item/modular_computer, update_tablet_open_uis), user)
	hardware.update_appearance(UPDATE_ICON)
	return TRUE

/datum/operating_system/sosix/ntos/kill_program(datum/computer_file/program/program)
	..()
	var/mob/user = usr
	program.on_kill(user)
	if(program == hardware.active_program)
		hardware.active_program = null
		if(!QDELETED(hardware) && hardware.enabled && user)
			INVOKE_ASYNC(hardware, TYPE_PROC_REF(/obj/item/modular_computer, update_tablet_open_uis), user)
	else if(program in idle_threads)
		idle_threads.Remove(program)
	else
		return FALSE

	if(program.program_flags & PROGRAM_REQUIRES_NTNET)
		var/obj/item/card/id/ID = hardware.stored_id?.GetID()
		program.generate_network_log("Connection closed -- Program ID: [program.filename] User:[ID ? "[ID.registered_name]" : "None"]")

	hardware.update_appearance(UPDATE_ICON)
	SEND_SIGNAL(program, COMSIG_COMPUTER_PROGRAM_KILL, user)

/**
 * store_file
 *
 * Adds an already initialized file to the computer, checking if one already exists.
 * Returns TRUE if successfully stored, FALSE otherwise.
 * user is optional: If set, the action was done by a mob/player
 */
/datum/operating_system/sosix/ntos/store_file(datum/computer_file/file_storing, mob/user)
	if(!file_storing || !istype(file_storing))
		return FALSE
	if(!can_store_file(file_storing))
		return FALSE

	// This file is already stored. Don't store it again.
	if(file_storing in hardware.stored_files)
		return FALSE

	file_storing.computer = hardware
	hardware.used_capacity += file_storing.size
	SEND_SIGNAL(file_storing, COMSIG_COMPUTER_FILE_STORE, hardware, user)
	SEND_SIGNAL(hardware, COMSIG_MODULAR_COMPUTER_FILE_STORE, file_storing, user)
	return TRUE

/**
 * remove_file
 *
 * Removes a given file from the computer, if possible.
 * Properly checking if the file even exists and is in the computer.
 * Returns TRUE if successfully completed, FALSE otherwise
 */
/datum/operating_system/sosix/ntos/remove_file(datum/computer_file/file_removing)
	if(!file_removing || !istype(file_removing))
		return FALSE
	if(!(file_removing in hardware.stored_files))
		return FALSE
	if(istype(file_removing, /datum/computer_file/program))
		var/datum/computer_file/program/program_file = file_removing
		kill_program(program_file)

	hardware.stored_files.Remove(file_removing)
	hardware.used_capacity -= file_removing.size
	SEND_SIGNAL(src, COMSIG_MODULAR_COMPUTER_FILE_DELETE, file_removing)
	SEND_SIGNAL(file_removing, COMSIG_COMPUTER_FILE_DELETE, src)
	qdel(file_removing)
	return TRUE

/**
 * can_store_file
 *
 * Checks if a computer can store a file, as computers can only store unique files.
 * returns TRUE if possible, FALSE otherwise.
 */
/datum/operating_system/sosix/ntos/can_store_file(datum/computer_file/file)
	if(!file || !istype(file))
		return FALSE
	if(file in hardware.stored_files)
		return FALSE
	if(find_file_by_name(file.filename))
		return FALSE
	// In the unlikely event someone manages to create that many files.
	// BYOND is acting weird with numbers above 999 in loops (infinite loop prevention)
	if(hardware.stored_files.len >= 999)
		return FALSE
	if((hardware.used_capacity + file.size) > hardware.max_capacity)
		return FALSE
	if(!file.can_store_file(src))
		return FALSE

	return TRUE

/**
 * find_file_by_name
 *
 * Will check all applications in a tablet for files and, if they have \
 * the same filename (disregarding extension), will return it.
 * If a computer disk is passed instead, it will check the disk over the computer.
 */
/datum/operating_system/sosix/ntos/find_file_by_name(filename, obj/item/disk/computer/target_disk)
	if(!istext(filename))
		return null
	if(isnull(target_disk))
		for(var/datum/computer_file/file as anything in hardware.stored_files)
			if(file.filename == filename)
				return file
	else
		for(var/datum/computer_file/file as anything in target_disk.stored_files)
			if(file.filename == filename)
				return file
	return null

/**
 * find_file_by_full_name
 *
 * Will check all applications in a tablet for files and, if they have \
 * the same filename AND extension, will return it.
 * If a computer disk is passed instead, it will check the disk over the computer.
 */
/datum/operating_system/sosix/ntos/find_file_by_full_name(full_path, obj/item/disk/computer/target_disk)
	if(!istext(full_path))
		return null
	if(isnull(target_disk))
		for(var/datum/computer_file/file as anything in hardware.stored_files)
			if("[file.filename].[file.filetype]" == full_path)
				return file
	else
		for(var/datum/computer_file/file as anything in target_disk.stored_files)
			if("[file.filename].[file.filetype]" == full_path)
				return file
	return null

/**
 * find_file_by_uid
 *
 * Will check all files in this computer and returns the file with the matching uid.
 * A file's uid is always unique to them, so this proc is sometimes preferable over find_file_by_name.
 * If a computer disk is passed instead, it will check the disk over the computer.
 */
/datum/operating_system/sosix/ntos/find_file_by_uid(uid, obj/item/disk/computer/target_disk)
	if(!isnum(uid))
		return null
	if(isnull(target_disk))
		for(var/datum/computer_file/file as anything in hardware.stored_files)
			if(file.uid == uid)
				return file
	else
		for(var/datum/computer_file/file as anything in target_disk.stored_files)
			if(file.uid == uid)
				return file
	return null
