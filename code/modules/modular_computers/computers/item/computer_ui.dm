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

	os.interact(user)
