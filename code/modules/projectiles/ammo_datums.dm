///List of all ammo types. Used by guns to tell the projectile how to act.
GLOBAL_LIST_INIT(ammo_list, init_ammo_list())

/proc/init_ammo_list()
	. = list()
	// Our ammo stuff is initialized here.
	for(var/t in subtypesof(/datum/ammo))
		// We don't want placeholders
		if(is_abstract(t))
			continue
		var/datum/ammo/A = new t
		.[A.type] = A

/**
 * # The base ammo datum
 *
 * This datum is the base for absolutely every ammo type in the game.
*/
ABSTRACT_TYPE(/datum/ammo)
	var/name = "generic bullet"
	var/icon = 'icons/obj/projectiles.dmi'
	var/icon_state = "bullet"
	///used in icons/obj/items/ammo for use in generating handful sprites
	var/handful_icon_state = "bullet"
	///how much of this ammo you can carry in a handful
	var/handful_amount = 8
	///Bullet type on the Ammo HUD
	var/hud_state = "unknown"
	var/hud_state_empty = "unknown"
	///The icon that is displayed when the bullet bounces off something.
	var/ping = "ping_b"
	///When it deals damage.
	var/sound_hit
	///When it's blocked by human armor.
	var/sound_armor
	///When it misses someone.
	var/sound_miss
	///When it bounces off something.
	var/sound_bounce

	///For most guns, this is where the bullet dramatically looses accuracy. Not for snipers though
	var/accurate_range = 5
	///Snipers use this to simulate poor accuracy at close ranges
	var/accurate_range_min = 0
	///This will de-increment a counter on the bullet
	var/max_range = 20
	///How much the ammo scatters when burst fired, added to gun scatter, along with other mods
	var/scatter = 0
	///This is the base damage of the bullet as it is fired
	var/damage = 0
	///How much damage the bullet loses per turf traveled
	var/damage_falloff = 1
	///DAMAGE_BRUTE, DAMAGE_BURN, DAMAGE_TOXIN, DAMAGE_OXY, DAMAGE_CLONE, DAMAGE_PAIN are the only things that should be in here
	var/damage_type = DAMAGE_BRUTE
	///How much armor it ignores before calculations take place
	var/penetration = 0
	///The % chance it will imbed in a human
	var/embed_chance = 0
	///How fast the projectile moves
	var/shell_speed = 2
	///Type path of the extra projectiles
	var/bonus_projectiles_type
	///How many extra projectiles it shoots out. Works kind of like firing on burst, but all of the projectiles travel together
	var/bonus_projectiles_amount = 0
	///Degrees scattered per two projectiles, each in a different direction.
	var/bonus_projectiles_scatter = 8
	///How far the bullet can travel before incurring a chance of hitting barricades; normally 1.
	var/barricade_clear_distance = 1
	///Does this have an override for the armor type the ammo should test? Bullet by default
	var/armor_type = BULLET
	///how much damage airbursts do to mobs around the target, multiplier of the bullet's damage
	var/airburst_multiplier = 0.1
	///What kind of behavior the ammo has
	var/ammo_behavior_flags = NONE
	///Determines what color our bullet will be when it flies
	var/bullet_color = COLOR_WHITE
	///If this ammo is hitscan, the icon of beam coming out from the gun
	var/hitscan_effect_icon = "beam"
	///A multiplier applied to piercing projectile, that reduces its damage/penetration on hit
	var/on_pierce_multiplier = 1
	///Base fire stacks added on hit if the projectile has AMMO_INCENDIARY
	var/incendiary_strength = 10

/datum/ammo/proc/do_at_max_range(turf/target_turf, obj/projectile/proj)
	return

///Does it do something special when shield blocked? Ie. a flare or grenade that still blows up.
/datum/ammo/proc/on_shield_block(mob/target_mob, obj/projectile/proj)
	return

///Special effects when hitting dense turfs.
/datum/ammo/proc/on_hit_turf(turf/target_turf, obj/projectile/proj)
	return

///Special effects when hitting mobs.
/datum/ammo/proc/on_hit_mob(mob/target_mob, obj/projectile/proj)
	return

///Special effects when hitting objects.
/datum/ammo/proc/on_hit_obj(obj/target_obj, obj/projectile/proj)
	return

///Special effects for leaving a turf. Only called if the projectile has AMMO_LEAVE_TURF enabled
/datum/ammo/proc/on_leave_turf(turf/target_turf, obj/projectile/proj)
	return

/datum/ammo/proc/airburst(atom/target, obj/projectile/proj)
	if(!target || !proj)
		CRASH("airburst() error: target [isnull(target) ? "null" : target] | proj [isnull(proj) ? "null" : proj]")
	for(var/mob/living/carbon/victim in orange(1, target))
		if(proj.firer == victim)
			continue
		victim.visible_message(SPAN_DANGER("[victim] is hit by backlash from \a [proj.name]!"),
			SPAN_DANGER("You are hit by backlash from \a </b>[proj.name]</b>!"))
		victim.apply_damage(proj.damage * airburst_multiplier, proj.ammo.damage_type, used_weapon = proj.fired_from)

/**
 * Fires additional projectiles, generally considered to still be originating from a gun
 * Such a buckshot
 * origin_override used to have the new projectile(s) originate from a different source than the main projectile
*/
/datum/ammo/proc/fire_bonus_projectiles(obj/projectile/main_proj, mob/living/shooter, atom/source, range, speed, angle, target, origin_override) //todo: Combine these procs with extra args or something, as they are quite similar
	var/tracer_type = ""
	var/proj_type = /obj/projectile
	if(main_proj.hitscan)
		tracer_type = main_proj.tracer_type
	for(var/i = 1 to bonus_projectiles_amount) //Want to run this for the number of bonus projectiles.
		var/obj/projectile/new_proj = new proj_type(main_proj.loc, tracer_type)
		if(bonus_projectiles_type)
			new_proj.generate_bullet(bonus_projectiles_type)
		else //If no bonus type is defined then the extra projectiles are the same as the main one.
			new_proj.generate_bullet(src)

		if(isgun(source))
			var/obj/item/gun/gun = source
			//gun.apply_gun_modifiers(new_proj, target, shooter)

		//Scatter here is how many degrees extra stuff deviate from the main projectile, first two the same amount, one to each side, and from then on the extra pellets keep widening the arc.
		var/new_angle = angle + (main_proj.ammo.bonus_projectiles_scatter * ((i % 2) ? (-(i + 1) * 0.5) : (i * 0.5)))
		if(new_angle < 0)
			new_angle += 360
		else if(new_angle > 360)
			new_angle -= 360
//		new_proj.fire_at(target, shooter, source, range, speed, new_angle, TRUE, loc_override = origin_override)

///A variant of Fire_bonus_projectiles without fixed scatter and no link between gun and bonus_projectile accuracy
/datum/ammo/proc/fire_directionalburst(obj/projectile/main_proj, mob/living/shooter, atom/source, projectile_amount, angle, target, loc_override)
	var/effect_icon = ""
	var/proj_type = /obj/projectile
	for(var/i = 1 to projectile_amount) //Want to run this for the number of bonus projectiles.
		var/atom/used_loc = loc_override ? loc_override : main_proj.loc
		var/obj/projectile/new_proj = new proj_type(used_loc, effect_icon)
		// we do this so if we place inside something, we fly out of it instead of hitting it
		new_proj.impacted += used_loc.contents
		if(bonus_projectiles_type)
			new_proj.generate_bullet(bonus_projectiles_type)
		else //If no bonus type is defined then the extra projectiles are the same as the main one.
			new_proj.generate_bullet(src)

		if(isgun(source))
			var/obj/item/gun/gun = source
			//gun.apply_gun_modifiers(new_proj, target)

		//Scatter here is how many degrees extra stuff deviate from the main projectile's firing angle. Fully randomised with no 45 degree cap like normal bullets
		var/f = (i-1)
		var/new_angle = angle + (main_proj.ammo.bonus_projectiles_scatter * ((f % 2) ? (-(f + 1) * 0.5) : (f * 0.5)))
		if(new_angle < 0)
			new_angle += 360
		if(new_angle > 360)
			new_angle -= 360
//		new_proj.fire_at(target, shooter, loc_override ? loc_override : main_proj.loc, null, null, new_angle, TRUE, scan_loc = TRUE)

/datum/ammo/proc/drop_flame(turf/T)
	if(!istype(T))
		return
	//T.ignite(20, 20)


/datum/ammo/proc/set_smoke()
	return


/datum/ammo/proc/drop_nade(turf/T)
	return

///called on projectile process() when AMMO_SPECIAL_PROCESS flag is active
/datum/ammo/proc/ammo_process(obj/projectile/proj, damage)
	CRASH("ammo_process called with unimplemented process!")

/*
//================================================
					Default Ammo
//================================================
*/
//Only when things screw up do we use this as a placeholder.
/datum/ammo/bullet
	name = "default bullet"
	icon_state = "bullet"
	ammo_behavior_flags = AMMO_BALLISTIC
//	sound_hit = SFX_BALLISTIC_HIT
//	sound_armor = SFX_BALLISTIC_ARMOR
//	sound_miss = SFX_BALLISTIC_MISS
//	sound_bounce = SFX_BALLISTIC_BOUNCE
//	point_blank_range = 2
	accurate_range_min = 0
	shell_speed = 3
	damage = 10
//	shrapnel_chance = 10
	bullet_color = COLOR_VERY_SOFT_YELLOW
	barricade_clear_distance = 2
