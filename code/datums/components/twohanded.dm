/**
 * Two Handed Component
 *
 * When applied to an item it will make it two handed
 *
 */

/datum/component/two_handed
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS // Only one of the component can exist on an item
	/// Are we holding the two handed item properly
	var/wielded = FALSE
	/// The multiplier applied to force when wielded, does not work with force_wielded, and force_unwielded
	var/force_multiplier = 0
	/// The force of the item when wielded
	var/force_wielded = null
	/// The force of the item when unwielded
	var/force_unwielded = null
	/// Play sound when wielded
	var/wieldsound = FALSE
	/// Play sound when unwielded
	var/unwieldsound = FALSE
	/// Play sound on attack when wielded
	var/attacksound = FALSE
	/// Does it have to be held in both hands
	var/require_twohands = FALSE
	/// The icon that will be used when wielded
	var/icon_wielded = FALSE
	/// Reference to the offhand created for the item
	var/obj/item/offhand/offhand_item = null

/**
 * Two Handed component
 *
 * vars:
 * * require_twohands (optional) Does the item need both hands to be carried
 * * wieldsound (optional) The sound to play when wielded
 * * unwieldsound (optional) The sound to play when unwielded
 * * attacksound (optional) The sound to play when wielded and attacking
 * * force_multiplier (optional) The force multiplier when wielded, do not use with force_wielded, and force_unwielded
 * * force_wielded (optional) The force setting when the item is wielded, do not use with force_multiplier
 * * force_unwielded (optional) The force setting when the item is unwielded, do not use with force_multiplier
 * * icon_wielded (optional) The icon to be used when wielded
 */
/datum/component/two_handed/Initialize(require_twohands=FALSE, wieldsound=FALSE, unwieldsound=FALSE, attacksound=FALSE, \
										force_multiplier=0, force_wielded=null, force_unwielded=null, icon_wielded=FALSE)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE

	src.require_twohands = require_twohands
	src.wieldsound = wieldsound
	src.unwieldsound = unwieldsound
	src.attacksound = attacksound
	src.force_multiplier = force_multiplier
	src.force_wielded = force_wielded
	src.force_unwielded = force_unwielded
	src.icon_wielded = icon_wielded

// Inherit the new values passed to the component
/datum/component/two_handed/InheritComponent(datum/component/two_handed/new_comp, original, require_twohands, wieldsound, unwieldsound, \
											force_multiplier, force_wielded, force_unwielded, icon_wielded)
	if(!original)
		return
	if(require_twohands)
		src.require_twohands = require_twohands
	if(wieldsound)
		src.wieldsound = wieldsound
	if(unwieldsound)
		src.unwieldsound = unwieldsound
	if(attacksound)
		src.attacksound = attacksound
	if(force_multiplier)
		src.force_multiplier = force_multiplier
	if(force_wielded)
		src.force_wielded = force_wielded
	if(force_unwielded)
		src.force_unwielded = force_unwielded
	if(icon_wielded)
		src.icon_wielded = icon_wielded

/datum/component/two_handed/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equip))
	RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_drop))
	RegisterSignal(parent, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_attack_self))
	RegisterSignal(parent, COMSIG_ITEM_ATTACK, PROC_REF(on_attack))
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_ICON, PROC_REF(on_update_icon))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/component/two_handed/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ITEM_EQUIPPED,
								COMSIG_ITEM_DROPPED,
								COMSIG_ITEM_ATTACK_SELF,
								COMSIG_ITEM_ATTACK,
								COMSIG_ATOM_UPDATE_ICON,
								COMSIG_MOVABLE_MOVED))

/// Triggered on equip of the item containing the component
/datum/component/two_handed/proc/on_equip(datum/source, mob/user, slot)
	SIGNAL_HANDLER

	if(require_twohands && (slot == slot_r_hand || slot == slot_l_hand))
		wield(user)
	if(!user.is_holding(parent) && wielded && !require_twohands)
		unwield(user)

/// Triggered on drop of item containing the component
/datum/component/two_handed/proc/on_drop(datum/source, mob/user)
	SIGNAL_HANDLER

	if(require_twohands)
		unwield(user, show_message=TRUE)
	if(wielded)
		unwield(user)
	if(source == offhand_item && !QDELETED(source))
		qdel(source)

/**
 * Wield the two handed item in both hands
 *
 * vars:
 * * user The mob/living/carbon that is wielding the item
 */
/datum/component/two_handed/proc/wield(mob/living/carbon/user, instant = FALSE)
	if(wielded)
		return
	if(islesserform(user))
		to_chat(user, span_warning("It's too heavy for you to wield fully."))
		return
	if(user.get_inactive_held_item())
		if(require_twohands)
			to_chat(user, span_notice("[parent] is too cumbersome to carry in one hand!"))
			user.drop_from_inventory(parent, get_turf(parent), force=TRUE)
		else
			to_chat(user, span_warning("You need your other hand to be empty!"))
		return
	if(user.usable_hands < 2)
		if(require_twohands)
			user.drop_from_inventory(parent, get_turf(parent), force=TRUE)
		to_chat(user, span_warning("You don't have enough intact hands."))
		return

	// wield update status
	if(SEND_SIGNAL(parent, COMSIG_TWOHANDED_WIELD, user, instant) & COMPONENT_TWOHANDED_BLOCK_WIELD)
		return // blocked wield from item
	wielded = TRUE
	ADD_TRAIT(parent, TRAIT_WIELDED, REF(src))
	RegisterSignal(user, COMSIG_MOB_SWAPPING_HANDS, PROC_REF(on_swap_hands))

	// update item stats and name
	var/obj/item/parent_item = parent
	if(force_multiplier)
		parent_item.force *= force_multiplier
	else if(!isnull(force_wielded))
		parent_item.force = force_wielded
	parent_item.name = "[parent_item.name] (Wielded)"
	parent_item.update_icon()

	if(istype(user,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		H.update_inv_l_hand()
		H.update_inv_r_hand()

	if(isrobot(user))
		to_chat(user, span_notice("You dedicate your module to [parent]."))
	else
		to_chat(user, span_notice("You grab [parent] with both hands."))

	// Play sound if one is set
	if(wieldsound)
		playsound(parent_item.loc, wieldsound, 50, TRUE)

	// Let's reserve the other hand
	offhand_item = new(user)
	offhand_item.name = "[parent_item.name] - offhand"
	offhand_item.desc = "Your second grip on [parent_item]."
	offhand_item.wielded = TRUE
	RegisterSignal(offhand_item, COMSIG_ITEM_DROPPED, PROC_REF(on_drop))
	user.put_in_inactive_hand(offhand_item)

/**
 * Unwield the two handed item
 *
 * vars:
 * * user The mob/living/carbon that is unwielding the item
 * * show_message (option) show a message to chat on unwield
 */
/datum/component/two_handed/proc/unwield(mob/living/carbon/user, show_message=TRUE)
	if(!wielded)
		return

	// wield update status
	wielded = FALSE
	REMOVE_TRAIT(parent, TRAIT_WIELDED, REF(src))
	UnregisterSignal(user, COMSIG_MOB_SWAPPING_HANDS)
	SEND_SIGNAL(parent, COMSIG_TWOHANDED_UNWIELD, user)

	// update item stats
	var/obj/item/parent_item = parent
	if(force_multiplier)
		parent_item.force /= force_multiplier
	else if(!isnull(force_unwielded))
		parent_item.force = force_unwielded

	// update the items name to remove the wielded status
	var/sf = findtext(parent_item.name, " (Wielded)", -10) // 10 == length(" (Wielded)")
	if(sf)
		parent_item.name = copytext(parent_item.name, 1, sf)
	else
		parent_item.name = "[initial(parent_item.name)]"

	// Update icons
	parent_item.update_appearance()
	if(user.get_item_by_slot(ITEM_SLOT_BACK) == parent)
		user.update_inv_back()
	else
		user.update_inv_hands()

	// if the item requires two handed drop the item on unwield
	if(require_twohands)
		user.dropItemToGround(parent, force=TRUE)

	// Show message if requested
	if(show_message)
		if(isrobot(user))
			to_chat(user, span_notice("You free up your module."))
		else if(require_twohands)
			to_chat(user, span_notice("You drop [parent]."))
		else
			to_chat(user, span_notice("You are now carrying [parent] with one hand."))

	// Play sound if set
	if(unwieldsound)
		playsound(parent_item.loc, unwieldsound, 50, TRUE)

	// Remove the object in the offhand
	if(offhand_item)
		UnregisterSignal(offhand_item, COMSIG_ITEM_DROPPED)
		qdel(offhand_item)
	// Clear any old reference to an item that should be gone now
	offhand_item = null
