/datum/operating_system/sosix/ntos/mobile
	name = "NTOS Mobile"
	description = "A streamlined version of NTOS designed for mobile modular computers."
	max_idle_programs = 2
	device_theme = PDA_THEME_NTOS

	///The program currently active on the tablet.
	var/datum/computer_file/program/active_program

	///Static list of default PDA apps to install on Initialize.
	var/static/list/datum/computer_file/pda_programs = list(
		/datum/computer_file/program/messenger,
		/datum/computer_file/program/nt_pay,
		/datum/computer_file/program/notepad,
		/datum/computer_file/program/crew_manifest,
	)

/datum/operating_system/sosix/ntos/mobile/install(mob/user)
	..()
	for(var/programs in pda_programs)
		var/datum/computer_file/program_type = new programs
		store_file(program_type)

/datum/operating_system/sosix/ntos/mobile/activate_program(mob/user, datum/computer_file/program/program)
	..()
	active_program?.background_program()
	active_program = program
	program.on_made_active_program(user)
