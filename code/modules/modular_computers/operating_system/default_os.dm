/datum/operating_system/default
	///List of stored files on this drive. Use `store_file` and `remove_file` instead of modifying directly!
	var/list/datum/computer_file/stored_files = list()

	var/obj/item/modular_computer/operating_computer

/datum/operating_system/default/New(obj/item/modular_computer/computer)
	..()
	operating_computer = computer

/datum/operating_system/default/ui_act(action, params, ui, state)
	..()
	switch(action)
		if("shutdown")
			return shutdown(ui.user)
		if("run_program")
			return run_program(ui.user, params["name"])
		if("kill_program")
			return kill_program(ui.user, params["name"])
	return FALSE

/datum/operating_system/default/proc/run_program(mob/user, program)
	..()

/datum/operating_system/default/proc/kill_program(mob/user, program)
	..()
