/* Beds... get your mind out of the gutter, they're for sleeping!
 * Contains:
 * 		Beds
 *		Roller beds
 */

/*
 * Beds
 */
/obj/structure/bed
	name = "bed"
	desc = "This is used to lie in, sleep in or strap on."
	icon_state = "bed"
	icon = 'icons/obj/stools-chairs-beds.dmi'
	layer = BELOW_OBJ_LAYER
	anchored = 1
	var/sheet_type = /obj/item/stack/sheet/metal
	var/sheet_amt = 1

	var/lock_type = /datum/locking_category/buckle/bed

/obj/structure/bed/alien
	name = "resting contraption"
	desc = "This looks similar to contraptions from earth. Could aliens be stealing our technology?"
	icon_state = "abed"

/obj/structure/bed/cultify()
	var/obj/structure/bed/chair/wood/wings/I = new /obj/structure/bed/chair/wood/wings(loc)
	I.dir = dir
	. = ..()

/obj/structure/bed/Cross(atom/movable/mover, turf/target, height=1.5, air_group = 0)
	if(air_group || (height==0))
		return 1
	if(istype(mover) && mover.checkpass(PASSTABLE)) //NOTE: This includes ALL chairs as well! Vehicles have their own override.
		return 1
	return ..()

/obj/structure/bed/attack_paw(mob/user as mob)
	return attack_hand(user)

/obj/structure/bed/attack_hand(mob/user as mob)
	manual_unbuckle(user)

/obj/structure/bed/attack_animal(mob/user as mob)
	manual_unbuckle(user)

/obj/structure/bed/attack_robot(mob/user as mob)
	if(Adjacent(user))
		manual_unbuckle(user)

/obj/structure/bed/MouseDrop(atom/over_object)
	return

/obj/structure/bed/MouseDrop_T(mob/M as mob, mob/user as mob)
	if(!istype(M))
		return

	buckle_mob(M, user)

/obj/structure/bed/proc/manual_unbuckle(mob/user as mob)
	if(!is_locking(lock_type))
		return

	if(user.size <= SIZE_TINY)
		to_chat(user, "<span class='warning'>You are too small to do that.</span>")
		return

	var/mob/M = get_locked(lock_type)[1]
	if(M != user)
		M.visible_message(\
			"<span class='notice'>[M] was unbuckled by [user]!</span>",\
			"You were unbuckled from \the [src] by [user].",\
			"You hear metal clanking.")
	else
		M.visible_message(\
			"<span class='notice'>[M] unbuckled \himself!</span>",\
			"You unbuckle yourself from \the [src].",\
			"You hear metal clanking.")
	playsound(src, 'sound/misc/buckle_unclick.ogg', 50, 1)
	unlock_atom(M)

	add_fingerprint(user)

/obj/structure/bed/proc/buckle_mob(mob/M as mob, mob/user as mob)
	if(!Adjacent(user) || user.incapacitated() || istype(user, /mob/living/silicon/pai))
		return

	if(!ismob(M) || (M.loc != src.loc)  || M.locked_to)
		return

	for(var/mob/living/L in get_locked(lock_type))
		to_chat(user, "<span class='warning'>Somebody else is already buckled into \the [src]!</span>")
		return

	if(user.size <= SIZE_TINY) //Fuck off mice
		to_chat(user, "<span class='warning'>You are too small to do that.</span>")
		return

	if(isanimal(M))
		if(M.size <= SIZE_TINY) //Fuck off mice
			to_chat(user, "<span class='warning'>The [M] is too small to buckle in.</span>")
			return

	if(istype(M, /mob/living/carbon/slime))
		to_chat(user, "<span class='warning'>The [M] is too squishy to buckle in.</span>")
		return

	if(M == usr)
		M.visible_message(\
			"<span class='notice'>[M.name] buckles in!</span>",\
			"You buckle yourself to [src].",\
			"You hear metal clanking.")
	else
		M.visible_message(\
			"<span class='notice'>[M.name] is buckled in to [src] by [user.name]!</span>",\
			"You are buckled in to [src] by [user.name].",\
			"You hear metal clanking.")

	playsound(src, 'sound/misc/buckle_click.ogg', 50, 1)
	add_fingerprint(user)

	lock_atom(M, lock_type)

	if(M.pulledby)
		M.pulledby.start_pulling(src)

/*
 * Roller beds
 */

#define ROLLERBED_Y_OFFSET

/obj/structure/bed/roller
	name = "roller bed"
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "down"
	anchored = 0
	var/up_state ="up"
	var/down_state = "down"
	var/roller_type = /obj/item/roller

	lockflags = DENSE_WHEN_LOCKED
	lock_type = /datum/locking_category/buckle/bed/roller

/obj/structure/bed/roller/deff
	icon = 'maps/defficiency/medbay.dmi'
	roller_type = /obj/item/roller/deff

/obj/item/roller
	name = "roller bed"
	desc = "A collapsed roller bed that can be carried around."
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "folded"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/lokiamis.dmi', "right_hand" = 'icons/mob/in-hand/right/lokiamis.dmi')
	item_state = "folded"
	var/bed_type = /obj/structure/bed/roller
	w_class = W_CLASS_LARGE // Can't be put in backpacks. Oh well.

/obj/item/roller/deff
	icon = 'maps/defficiency/medbay.dmi'
	bed_type = /obj/structure/bed/roller/deff

/obj/item/roller/attack_self(mob/user)
	var/obj/structure/bed/roller/R = new bed_type(user.loc)
	R.add_fingerprint(user)
	qdel(src)

/obj/structure/bed/roller/lock_atom(var/atom/movable/AM)
	. = ..()
	if(!.)
		return

	icon_state = up_state

/obj/structure/bed/roller/unlock_atom(var/atom/movable/AM)
	. = ..()
	if(!.)
		return

	icon_state = down_state

/obj/structure/bed/roller/MouseDrop(over_object, src_location, over_location)
	..()
	if(over_object == usr && Adjacent(usr))
		if(!ishigherbeing(usr) || usr.incapacitated() || usr.lying)
			return

		if(is_locking(lock_type))
			return 0

		visible_message("[usr] collapses \the [src.name].")

		new roller_type(get_turf(src))

		qdel(src)

/obj/structure/bed/attackby(obj/item/weapon/W, mob/user)
	if(istype(W,/obj/item/roller_holder))
		manual_unbuckle(user)
	if(iswrench(W))
		playsound(src, 'sound/items/Ratchet.ogg', 50, 1)
		drop_stack(sheet_type, loc, 2, user)
		qdel(src)
		return

	. = ..()

/obj/structure/bed/roller/attackby(obj/item/weapon/W, mob/user)
	..()
	if(istype(W,/obj/item/roller_holder))
		var/obj/item/roller_holder/RH = W
		if(!RH.held)
			to_chat(user, "<span class='notice'>You collect \the [src].</span>")
			src.forceMove(RH)
			RH.held = src
			RH.update_icon()

/obj/item/roller_holder
	name = "roller bed rack"
	desc = "A rack for carrying a collapsed roller bed."
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "borgbed_stored"
	var/obj/structure/bed/roller/borg/held

/obj/item/roller_holder/update_icon()
	icon_state = "borgbed_[held ? "stored" : "deployed"]"

/obj/item/roller_holder/New()
	..()
	held = new(src)

/obj/item/roller_holder/attack_self(mob/user as mob)

	if(!held)
		to_chat(user, "<span class='notice'>The [src.name] is empty.</span>")
		return

	to_chat(user, "<span class='notice'>You deploy \the [held].</span>")
	held.add_fingerprint(user)
	held.forceMove(get_turf(src))
	held = null
	update_icon()

/obj/item/roller_holder/Destroy()
	if(held)
		qdel(held)
		held = null
	..()

/obj/item/roller/borg
	name = "hover roller bed"
	desc = "A collapsed cyborg hover roller bed that can be carried around."
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "borgbed_stored"
	bed_type = /obj/structure/bed/roller/borg

/obj/structure/bed/roller/borg
	name = "hover roller bed"
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "borgbed_down"
	up_state ="borgbed_up"
	down_state = "borgbed_down"
	roller_type = /obj/item/roller/borg

//A surgical roller bed that allows you to do surgery on it 100% of the time in place of the 75% chance of the normal one.
/obj/item/roller/surgery
	name = "mobile operating table"
	desc = "A collapsed mobile operating table that can be carried around."
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "adv_folded"
	bed_type = /obj/structure/bed/roller/surgery

/obj/structure/bed/roller/surgery
	name = "mobile operating table"
	desc = "A new meaning to saving people in the hall. It's much more stable than a regular roller bed."
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "adv_down"
	up_state ="adv_up"
	down_state = "adv_down"
	roller_type = /obj/item/roller/surgery

/datum/locking_category/buckle/bed
	flags = LOCKED_SHOULD_LIE

/datum/locking_category/buckle/bed/roller
	pixel_y_offset = 6 * PIXEL_MULTIPLIER
	flags = DENSE_WHEN_LOCKING | LOCKED_SHOULD_LIE
