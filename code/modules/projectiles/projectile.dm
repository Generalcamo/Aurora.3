#define MOVES_HITSCAN -1 //Not actually hitscan but close as we get without actual hitscan.
#define MUZZLE_EFFECT_PIXEL_INCREMENT 17 //How many pixels to move the muzzle flash up so your character doesn't look like they're shitting out lasers.
#define MAX_RANGE_HIT_PRONE_TARGETS 10 //How far do the projectile hits the prone mob

ABSTRACT_TYPE(/obj/projectile)
	name = "projectile"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "bullet"
	density = FALSE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	movement_type = FLYING
	blocks_emissive = EMISSIVE_BLOCK_GENERIC
	layer = MOB_LAYER
	///The sound this plays on impact.
	var/hitsound = 'sound/weapons/pierce.ogg'
	var/hitsound_wall = ""

	/// Should be `resistance_flags` but we don't have it yet.
	unacidable = TRUE
	/// What body part/area we're aiming at.
	var/def_zone = ""
	/// Atom who shot the projectile (Not the gun, the guy who shot the gun)
	var/atom/movable/firer = null
	// if the projectile was the result of a misfire. For logging.
	var/misfire = FALSE
	/// The thing that the projectile was fired from (gun, turret, spell).
	var/datum/fired_from = null
	/// Attack message.
	var/suppressed = FALSE
	/// The original target clicked.
	var/atom/original
	/// Initial target x coordinate offset of the projectile
	VAR_FINAL/xo = null
	/// Initial target y coordinate offset of the projectile
	VAR_FINAL/yo = null
	/// The projectile's starting turf.
	var/turf/starting
	/// pixel_x where the player clicked. Default is the center.
	var/p_x = 16
	/// pixel_y where the player clicked. Default is the center
	var/p_y = 16
	/// X coordinate at which the projectile entered a new turf
	var/entry_x
	/// Y coordinate at which the projectile entered a new turf
	var/entry_y
	/// X coordinate at which the projectile visually impacted the target
	var/impact_x
	/// Y coordinate at which the projectile visually impacted the target
	var/impact_y
	/// Turf of the last atom we've impacted
	VAR_FINAL/turf/last_impact_turf = null

	//Fired processing vars
	/// Have we been fired yet
	var/fired = FALSE
	/// For suspending the projectile midair
	var/paused = FALSE
	/// Last time the projectile moved, used for lag compensation if SSprojectiles starts chugging
	VAR_PRIVATE/last_projectile_move = 0
	/// Last time the projectile was processed, also used for lag compensation
	VAR_PRIVATE/last_process = 0
	/// How many pixels we missed last tick due to lag or speed cap
	VAR_PRIVATE/overrun = 0
	/// Projectile's movement vector - this caches sine/cosine of our angle to cut down on trig calculations
	var/datum/vector/movement_vector
	/// We already impacted these things, do not impact them again. Used to make sure we can pierce things we want to pierce. Lazylist, typecache style (object = TRUE) for performance.
	var/list/impacted = list()
	/// If TRUE, we can hit our firer.
	var/ignore_source_check = FALSE
	/// We are flagged PHASING temporarily to not stop moving when we Bump something but want to keep going anyways.
	var/temporary_unstoppable_movement = FALSE

	/** PROJECTILE PIERCING
	 * WARNING:
	 * Projectile piercing MUST be done using these variables.
	 * Ordinary passflags will result in can_hit_target being false unless directly clicked on - similar to projectile_phasing but without even going to process_hit.
	 * The two flag variables below both use pass flags.
	 * In the context of LETPASStHROW, it means the projectile will ignore things that are currently "in the air" from a throw.
	 *
	 * Also, projectiles sense hits using Bump(), and then pierce them if necessary.
	 * They simply do not follow conventional movement rules.
	 * NEVER flag a projectile as PHASING movement type.
	 * If you so badly need to make one go through *everything*, override check_pierce() for your projectile to always return PROJECTILE_PIERCE_PHASE/HIT.
	 */
	/// The "usual" flags of pass_flags is used in that can_hit_target ignores these unless they're specifically targeted/clicked on. This behavior entirely bypasses process_hit if triggered, rather than phasing which uses prehit_pierce() to check.
	pass_flags = PASSTABLE|PASSRAILING
	/// If FALSE, allow us to hit something directly targeted/clicked/whatnot even if we're able to phase through it.
	var/phasing_ignore_direct_target = FALSE
	/// Bitflag for things the projectile should just phase through entirely - No hitting unless direct target and [phasing_ignore_direct_target] is FALSE. Uses pass_flags flags.
	var/projectile_phasing = NONE
	/// Bitflag for things the projectile should hit, but pierce through without deleting itself. Defers to projectile_phasing. Uses pass_flags flags.
	var/projectile_piercing = NONE
	/// Number of times we've pierced something. Incremented BEFORE bullet_act and on_hit proc!
	var/pierces = 0
	///The base chance that a projectile capable of piercing will actually pierce.
	var/pierce_chance = 0
	/// 0-1 multiplier, the projectile's damage is modified by multiplying this after each pierce.
	var/pierce_decay_damage = 0.7
	///Used to determine whether or not to apply embed chances on hit.
	var/last_hit_pierced = FALSE
	/// If objects are below this layer, we pass through them.
	var/hit_threshhold = PROJECTILE_HIT_THRESHHOLD_LAYER

	/// How many tiles we pass in a single SSprojectiles tick
	var/speed = 2

	/// The current angle of the projectile. Initially null, so if the arg is missing from [/fire()], we can calculate it from firer and target as fallback.
	var/angle
	/// Angle at firing.
	var/original_angle = 0
	/// Set TRUE to prevent projectiles from having their sprites rotated based on firing angle.
	var/nondirectional_sprite = FALSE
	/// Amount (in degrees) of projectile spread.
	var/spread = 0
	/// Additional rotation for the projectile, in case it uses some object's sprite
	var/projectile_angle = 0
	/// Use SLIDE_STEPS in conjunction with legacy.
	animate_movement = NO_STEPS
	/// How many times we've ricochet'd so far (instance variable, not a stat).
	var/ricochets = 0
	/// How many times we can ricochet max.
	var/ricochets_max = 0
	/// How many times we have to ricochet min (unless we hit an atom we can ricochet off).
	var/min_ricochets = 0
	/// 0-100 (or more, I guess), the base chance of ricocheting, before being modified by the atom we shoot and our chance decay.
	var/ricochet_chance = 0
	/// 0-1 (or more, I guess) multiplier, the ricochet_chance is modified by multiplying this after each ricochet.
	var/ricochet_decay_chance = 0.7
	/// 0-1 (or more, I guess) multiplier, the projectile's damage is modified by multiplying this after each ricochet.
	var/ricochet_decay_damage = 0.7
	/// On ricochet, if nonzero, we consider all mobs within this range of our projectile at the time of ricochet to home in on like Revolver Ocelot, as governed by ricochet_auto_aim_angle.
	var/ricochet_auto_aim_range = 0
	/// On ricochet, if ricochet_auto_aim_range is nonzero, we'll consider any mobs within this range of the normal angle of incidence to home in on, higher = more auto aim.
	var/ricochet_auto_aim_angle = 30
	/// The angle of impact must be within this many degrees of the struck surface, set to 0 to allow any angle.
	var/ricochet_incidence_leeway = 40
	/// Can our ricochet autoaim hit our firer?
	var/ricochet_shoots_firer = TRUE
	/// accuracy modifier. Used as a multiplier
	var/accuracy_mod = 1

	///If the object being hit can pass ths damage on to something else, it should not do it for this bullet
	var/force_hit = FALSE

	//Hitscan
	/// Whether this projectile is hitscan. Hitscan projectiles are processed until the end of their path instantly upon being fired and leave a tracer in their path
	var/hitscan = FALSE
	/// Associated list of coordinate points in which we changed trajectories in order to calculate hitscan tracers
	/// Value points to the next point in the beam
	var/list/datum/point/beam_points
	/// Last point in the beam
	var/datum/point/last_point
	/// Next forceMove will not create tracer end/start effects
	var/free_hitscan_forceMove = FALSE
	// Used to prevent duplicate effects during lag chunking
	/// If a hitscan muzzle effect has been created for this "path", reset during forceMoves.
	var/spawned_muzzle = FALSE

	/// Hitscan tracer effect left behind the projectile
	var/tracer_type
	/// Hitscan muzzle effect spawned on the firer
	var/muzzle_type
	/// Hitscan impact effect spawned on the target
	var/impact_type

	//Fancy hitscan lighting effects!
	var/hitscan_light_intensity = 1.5
	var/hitscan_light_range = 0.75
	var/hitscan_light_color_override
	var/muzzle_flash_intensity = 3
	var/muzzle_flash_range = 1.5
	var/muzzle_flash_color_override
	var/impact_light_intensity = 3
	var/impact_light_range = 2
	var/impact_light_color_override

	//Homing
	/// If the projectile is currently homing. Warning - this changes projectile's processing logic, reverting it to segmented processing instead of new raymarching logic
	/// This does not actually set up the projectile to home in on a target - you need to set that up with set_homing_target() on the projectile!
	VAR_FINAL/homing = FALSE
	/// Target the projectile is homing on
	var/atom/homing_target
	/// Angles per move segment, distance is based on SSprojectiles.pixels_per_decisecond
	/// With pixels_per_decisecond set to 16 and homing_turn_speed, the projectile can turn up to 20 pixels per turf passed
	var/homing_turn_speed = 10
	/// In pixels for these. offsets are set once when setting target.
	var/homing_inaccuracy_min = 0
	var/homing_inaccuracy_max = 0
	var/homing_offset_x = 0
	var/homing_offset_y = 0

	var/damage = 10
	/// DAMAGE_BRUTE, DAMAGE_BURN, DAMAGE_TOXIN, DAMAGE_OXY, DAMAGE_CLONE, DAMAGE_PAIN are the only things that should be in here.
	var/damage_type = DAMAGE_BRUTE

	/// This will de-increment every step. When 0, it will deletze the projectile.
	var/range = 50
	/// Original range upon being fired/reflected
	var/maximum_range
	/// Amount of original range that falls off when reflecting, so it doesn't go forever.
	var/reflect_range_decrease = 5
	/// Can it be reflected or not?
	var/reflectable = NONE

	/// What type of impact effect to show when hitting something.
	var/impact_effect_type
	/// Is this type spammed enough to not log? (KAs).
	var/log_override = FALSE
	/// If true, the projectile won't cause any logging. Used for hallucinations and shit.
	var/do_not_log = FALSE

	/// Turf that we have registered connect_loc signal - this is done for performance, as we're moving ~a dozen turfs per tick
	/// and registering and unregistering signal for every single one of them is stupid. Unregistering the signal from the correct turf in case we get moved by smth else is important
	var/turf/last_tick_turf
	/// Remaining pixel movement last tick - used for precise range calculations
	var/pixels_moved_last_tile = 0
	/// In order to preserve animations, projectiles are only deleted the tick *after* they impact something.
	/// Same is applied to reaching the range limit
	var/deletion_queued = NONE
	/// How many ticks should we wait in queued deletion mode before qdeleting? Sometimes increased in animations
	var/ticks_to_deletion = 1

	/// Type of shrapnel the projectile leaves in its target.
	var/shrapnel_type

	/// If TRUE, hit mobs, even if they are lying on the floor and are not our target within MAX_RANGE_HIT_PRONE_TARGETS tiles.
	var/hit_prone_targets = FALSE
	/// If TRUE, ignores the range of MAX_RANGE_HIT_PRONE_TARGETS tiles of hit_prone_targets.
	var/ignore_range_hit_prone_targets = FALSE
	/// How much we want to drop damage per tile as it travels through the air.
	var/damage_falloff_tile
	/// How much accuracy is lost for each tile travelled.
	var/accuracy_falloff = 7
	/// How much accuracy before falloff starts to matter. Formula is range - falloff * tiles travelled.
	var/accurate_range = 100
	/// If TRUE, directly targeted turfs can be hit.
	var/can_hit_turfs = FALSE


	/*#########################################
		START AURORA SNOWFLAKE VARS SECTION
	#########################################*/

	/// Effect displayed when a bullet hits a barricade. See atom/proc/bullet_ping.
	var/ping_effect = "ping_b"

	/// Used for shooting at blank range, you shouldn't be able to miss.
	var/point_blank = FALSE

	/// Effects (bio and rad are also valid)
	var/damage_flags = DAMAGE_FLAG_BULLET
	/// Defines what armor to use when it hits things.  Must be set to bullet, laser, energy,or bomb
	var/check_armor = BULLET
	/// For different categories, IMPACT_MEAT etc
	var/list/impact_sounds

	var/stun = 0
	var/weaken = 0
	var/paralyze = 0
	var/irradiate = 0
	var/stutter = 0
	var/eyeblur = 0
	var/drowsy = 0
	var/agony = 0

	var/incinerate = 0
	/// Whether or not the projectile can embed itself in the mob
	var/embed = 0
	/// A flat bonus to the % chance to embed
	var/embed_chance = 0

	/// For maiming. Factor that the recipiant will be maimed by the projectile (NOT OUT OF 100%.)
	var/maim_rate = 0

	var/reflected = FALSE

	/// If greater than zero, the projectile will pass through dense objects as specified by prehit_pierce()
	var/penetrating = 0

	/// For KAs, really.
	var/aoe = 0

	/// How much the damage of this bullet is increased against mechs.
	var/anti_materiel_potential = 1

	/*########################################
		END AURORA SNOWFLAKE VARS SECTION
	########################################*/

/obj/projectile/Initialize()
	. = ..()
	maximum_range = range

/obj/projectile/Destroy()
	if(hitscan)
		generate_hitscan_tracers()
	STOP_PROCESSING(SSprojectiles, src)
	firer = null
	original = null
	QDEL_NULL(movement_vector)
	QDEL_LIST_ASSOC(beam_points)
	QDEL_NULL(last_point)
	return ..()

/// Called every time a projectile passes one tile worth of movement
/obj/projectile/proc/reduce_range()
	range--
	pixels_moved_last_tile -= ICON_SIZE_ALL
	if(damage_falloff_tile && damage >= 0)
		damage += damage_falloff_tile
	// if(stamina_falloff_tile && stamina >= 0)
	// 	stamina += stamina_falloff_tile

	SEND_SIGNAL(src, COMSIG_PROJECTILE_RANGE)
	if(range <= 0 && loc)
		if (hitscan)
			qdel(src)
			return
		deletion_queued = PROJECTILE_RANGE_DELETE

	// if(damage_falloff_tile && damage <= 0 || stamina_falloff_tile && stamina <= 0)
	if(damage_falloff_tile && damage <= 0)
		if (hitscan)
			qdel(src)
			return
		deletion_queued = PROJECTILE_RANGE_DELETE

/// Called next tick after the projectile reaches its maximum range so the animation has time to fully play out
/obj/projectile/proc/on_range()
	SEND_SIGNAL(src, COMSIG_PROJECTILE_RANGE_OUT)
	qdel(src)

/**
 * Called when the projectile hits something
 *
 * _NOT THE SAME OF TG_
 *
 * By default parent call will always return [BULLET_ACT_HIT] (unless qdeleted)
 * so it is save to assume a successful hit in children (though not necessarily successfully damaged - it could've been blocked)
 *
 * Arguments
 * * target - thing hit
 * * blocked - percentage of hit blocked (0 to 100)
 * * pierce_hit - boolean, are we piercing through or regular hitting - NOT THERE YET
 *
 * Returns
 * * Returns [BULLET_ACT_HIT] if we hit something. Default return value.
 * * Returns [BULLET_ACT_BLOCK] if we were hit but sustained no effects (blocked it). Note, Being "blocked" =/= "blocked is 100".
 * * Returns [BULLET_ACT_FORCE_PIERCE] to have the projectile keep going instead of "hitting", as if we were not hit at all.
 */
/obj/projectile/proc/on_hit(atom/target, blocked = 0, pierce_hit, var/def_zone = null)
	SHOULD_CALL_PARENT(TRUE)

	if(fired_from)
		SEND_SIGNAL(fired_from, COMSIG_PROJECTILE_ON_HIT, firer, target, angle, def_zone, blocked)
	SEND_SIGNAL(src, COMSIG_PROJECTILE_SELF_ON_HIT, firer, target, angle, def_zone, blocked)

	if(QDELETED(src) || deletion_queued) // in case one of the above signals deleted the projectile for whatever reason
		return BULLET_ACT_BLOCK
	var/turf/target_turf = get_turf(target)

	var/hitx
	var/hity
	if(target == original)
		impact_x = target.pixel_x + p_x - ICON_SIZE_X / 2
		impact_y = target.pixel_y + p_y - ICON_SIZE_Y / 2
	else
		impact_x = entry_x + movement_vector?.pixel_x * rand(0, ICON_SIZE_X / 2)
		impact_y = entry_y + movement_vector?.pixel_y * rand(0, ICON_SIZE_Y / 2)

	if(isturf(target_turf) && hitsound_wall)
		var/volume = clamp(vol_by_damage() + 20, 0, 100)
		if(suppressed)
			volume = 5
		playsound(loc, hitsound_wall, volume, TRUE, -1)

	if(blocked >= 100)	//Full block
		return BULLET_ACT_BLOCK

	if (hitsound)
		playsound(src, hitsound, vol_by_damage(), TRUE, -1)

	if(!isliving(target))
		if(impact_effect_type && !hitscan)
			new impact_effect_type(target_turf, hitx, hity)
		return BULLET_ACT_HIT

	var/mob/living/living_target = target

	living_target.apply_effects(0, weaken, paralyze, 0, stutter, eyeblur, drowsy, 0, incinerate, blocked)
	living_target.stun_effect_act(stun, agony, def_zone, src, damage_flags)
	living_target.apply_damage(irradiate, DAMAGE_RADIATION, damage_flags = DAMAGE_FLAG_DISPERSED) //radiation protection is handled separately from other armor types.

	if(!do_not_log)
		log_combat(firer, living_target, "shot", src)
		//Because `admin_attack_log` expects both to be mobs
		if(ismob(target) && ismob(firer))
			admin_attack_log(firer, living_target, "shot with \a [src.type]", "shot with \a [src.type]", "shot (\a [src.type])")

	return BULLET_ACT_HIT

/obj/projectile/proc/vol_by_damage()
	if(suppressed)
		return 5
	if(!damage)
		return 50
	else
		return clamp(damage * 0.67, 30, 100)// Multiply projectile damage by 0.67, then CLAMP the value between 30 and 100

/obj/projectile/proc/get_structure_damage_sound()
	if(damage_type == DAMAGE_BRUTE)
		return 'sound/effects/metalping.ogg'
	else if(damage_type == DAMAGE_BURN)
		return pick(SOUNDS_LASER_METAL)

/obj/projectile/proc/firer_deleted(datum/source)
	SIGNAL_HANDLER
	// Shooting yourself point-blank
	if (firer == original)
		original = null
	if (firer == fired_from)
		fired_from = null
	firer = null

/obj/projectile/proc/original_deleted(datum/source)
	SIGNAL_HANDLER
	original = null

/obj/projectile/proc/fired_from_deleted(datum/source)
	SIGNAL_HANDLER
	fired_from = null

/obj/projectile/proc/on_ricochet(atom/A)
	ricochets++
	if(!ricochet_auto_aim_angle || !ricochet_auto_aim_range)
		return

	var/mob/living/unlucky_sob
	var/best_angle = ricochet_auto_aim_angle
	if(firer && HAS_TRAIT(firer, TRAIT_NICE_SHOT))
		best_angle += NICE_SHOT_RICOCHET_BONUS
	for(var/mob/living/L in range(ricochet_auto_aim_range, src.loc))
		if(L.stat == DEAD || !is_in_sight(src, L) || (!ricochet_shoots_firer && L == firer))
			continue
		var/our_angle = abs(closer_angle_difference(angle, get_angle(src.loc, L.loc)))
		if(our_angle < best_angle)
			best_angle = our_angle
			unlucky_sob = L

	if(unlucky_sob)
		set_angle(get_angle(src, unlucky_sob.loc))
		original = unlucky_sob

/obj/projectile/proc/check_human_shield(atom/A)
	if(!isliving(A) || !starting)
		return FALSE

	var/mob/living/M = A
	if(point_blank || !(M.dir & get_dir(M, starting)))
		return FALSE

	for(var/obj/item/grab/G in list(M.l_hand, M.r_hand))
		if(!G?.affecting || G.state < GRAB_NECK || G.affecting.lying)
			continue
		M.visible_message(SPAN_DANGER("\The [M] uses [G.affecting] as a shield!"))
		return G.affecting

	return FALSE

/obj/projectile/Collide(atom/A)
	SEND_SIGNAL(src, COMSIG_MOVABLE_BUMP, A)
	if(can_hit_target(A, A == original, TRUE, TRUE))
		impact(A)

/**
 * Called when the projectile hits something
 * This can either be from it bumping something,
 * or it passing over a turf/being crossed and scanning that there is infact
 * a valid target it needs to hit.
 * This target isn't however necessarily WHAT it hits
 * that is determined by process_hit and select_target.
 *
 * Furthermore, this proc shouldn't check can_hit_target - this should only be called if can hit target is already checked.
 * Also, we select_target to find what to process_hit first.
 */
/obj/projectile/proc/Impact(atom/A)
	if(QDELETED(src))
		return TRUE
	if(!trajectory)
		qdel(src)
		return FALSE
	if(impacted[A.weak_reference]) // NEVER doublehit
		return FALSE
	var/turf/T = get_turf(A)
	var/atom/shield_target = check_human_shield(A)
	if(shield_target)
		var/datum/weakref/original_ref = A.weak_reference
		impacted[original_ref] = TRUE
		process_hit(T, shield_target, A)
		impacted -= original_ref
	var/datum/point/point_cache = trajectory.copy_to()
	if(ricochets < ricochets_max && check_ricochet_flag(A) && check_ricochet(A))
		ricochets++
		if(A.handle_ricochet(src))
			on_ricochet(A)
			impacted = list() // Shoot a x-ray laser at a pair of mirrors I dare you
			ignore_source_check = TRUE // Firer is no longer immune
			decayedRange = max(0, decayedRange - reflect_range_decrease)
			ricochet_chance *= ricochet_decay_chance
			damage *= ricochet_decay_damage
			// stamina *= ricochet_decay_damage
			range = decayedRange
			if(hitscan)
				store_hitscan_collision(point_cache)
			return TRUE

	if(ricochets < ricochets_max && check_ricochet_flag(target) && check_ricochet(target) && target.handle_ricochet(src))
		on_ricochet(target)
		impacted = list() // Shoot a x-ray laser at a pair of mirrors I dare you
		ignore_source_check = TRUE // Firer is no longer immune
		maximum_range = max(0, maximum_range - reflect_range_decrease)
		ricochet_chance *= ricochet_decay_chance
		damage *= ricochet_decay_damage
		// stamina *= ricochet_decay_damage
		range = maximum_range
		return

	last_impact_turf = get_turf(target)

	// If our target has TRAIT_DESIGNATED_TARGET, treat accuracy_falloff as 0
	//var/effective_accuracy = HAS_TRAIT(target, TRAIT_DESIGNATED_TARGET) ? 0 : accuracy_falloff
	var/effective_accuracy = accuracy_falloff

	def_zone = ran_zone(def_zone, clamp(accurate_range - (effective_accuracy * get_dist(last_impact_turf, starting)), 5, 100))

	var/impact_result = process_hit_loop(select_target(last_impact_turf, target))
	if (impact_result == PROJECTILE_IMPACT_PASSED)
		return
	if (hitscan)
		qdel(src)
		return
	deletion_queued = PROJECTILE_IMPACT_DELETE

/*
 * Main projectile hit loop code
 * As long as there are valid targets on the hit target's tile, we will loop through all the ones that we have not hit
 * (and thus invalidated) and try to hit them until either no targets remain or we've been deleted.
 * Should *never* be called directly, as impact() is the proc queueing projectiles for deletion
 * If you need to call this directly, you should reconsider the choices that led you to this point
 */
/obj/projectile/proc/process_hit_loop(atom/target)
	SHOULD_NOT_SLEEP(TRUE)
	PRIVATE_PROC(TRUE)

	// Don't impact anything if we've been queued for deletion
	if (deletion_queued)
		return PROJECTILE_IMPACT_PASSED

	var/turf/target_turf = get_turf(target)
	while (target && !QDELETED(src) && !deletion_queued)
		// Doublehitting can be an issue with slow projectiles or when the server is chugging
		impacted[WEAKREF(target)] = TRUE
		var/mode = prehit_pierce(target)
		if(mode == PROJECTILE_DELETE_WITHOUT_HITTING)
			return PROJECTILE_IMPACT_INTERRUPTED

		// If we've phasing through a target, first set ourselves as phasing and then try to locate a new one
		if(mode == PROJECTILE_PIERCE_PHASE)
			if(!(movement_type & PHASING))
				temporary_unstoppable_movement = TRUE
				movement_type |= PHASING
			target = select_target(target_turf, target)
			continue

		var/target_signal = SEND_SIGNAL(target, COMSIG_PROJECTILE_PREHIT, src)
		if (target_signal & PROJECTILE_INTERRUPT_HIT_PHASE)
			return PROJECTILE_IMPACT_PASSED
		if (target_signal & PROJECTILE_INTERRUPT_HIT)
			return PROJECTILE_IMPACT_INTERRUPTED

		var/self_signal = SEND_SIGNAL(src, COMSIG_PROJECTILE_SELF_PREHIT, target)
		if (self_signal & PROJECTILE_INTERRUPT_HIT_PHASE)
			return PROJECTILE_IMPACT_PASSED
		if (self_signal & PROJECTILE_INTERRUPT_HIT)
			return PROJECTILE_IMPACT_INTERRUPTED

		if(mode == PROJECTILE_PIERCE_HIT)
			pierces += 1

		// Targets should handle their impact logic on our own and if they decide that we hit them, they call our on_hit
		var/result = target.projectile_hit(src, def_zone, mode == PROJECTILE_PIERCE_HIT)
		if (result != BULLET_ACT_FORCE_PIERCE && max_pierces && pierces >= max_pierces)
			return PROJECTILE_IMPACT_SUCCESSFUL

		// If we're not piercing or phasing, delete ourselves
		if (result != BULLET_ACT_FORCE_PIERCE && mode != PROJECTILE_PIERCE_HIT && mode != PROJECTILE_PIERCE_PHASE)
			return PROJECTILE_IMPACT_SUCCESSFUL

		// We've piercing though this one, go look for a new target
		if(!(movement_type & PHASING))
			temporary_unstoppable_movement = TRUE
			movement_type |= PHASING

		target = select_target(target_turf, target)

	return PROJECTILE_IMPACT_PASSED

/**
 * Selects a target to hit from a turf
 *
 * @params
 * T - The turf
 * target - The "preferred" atom to hit, usually what we Bumped() first.
 * bumped - used to track if something is the reason we impacted in the first place.
 *    If set, this atom is always treated as dense by can_hit_target.
 *
 * Priority:
 * 0. Anything that is already in impacted is ignored no matter what. Furthermore, in any bracket, if the target atom parameter is in it, that's hit first.
 * Furthermore, can_hit_target is always checked. This (entire proc) is PERFORMANCE OVERHEAD!! But, it shouldn't be ""too"" bad and I frankly don't have a better *generic non snowflakey* way that I can think of right now at 3 AM.
 * FURTHERMORE, mobs/objs have a density check from can_hit_target - to hit non dense objects over a turf, you must click on them, same for mobs that usually wouldn't get hit.
 * 1. Special check on what we bumped to see if it's a border object that intercepts hitting anything behind it
 * 2. The thing originally aimed at/clicked on
 * 3. Mobs - picks lowest buckled mob to prevent scarp piggybacking memes
 * 4. Objs
 * 5. Turf
 * 6. Nothing
 */
/obj/projectile/proc/select_target(turf/our_turf, atom/target, atom/bumped)
	// 1. special bumped border object check
	// if((bumped?.flags_1 & ON_BORDER_1) && can_hit_target(bumped, original == bumped, TRUE, TRUE))
	if((bumped?.atom_flags & ATOM_FLAG_CHECKS_BORDER) && can_hit_target(bumped, original == bumped, TRUE, TRUE))
		return bumped
	// 2. original
	if(can_hit_target(original, TRUE, FALSE, original == bumped))
		return original
	var/list/atom/considering = list()  // let's define this ONCE
	// 3. mobs
	for(var/mob/living/iter_possible_target in our_turf)
		if(can_hit_target(iter_possible_target, iter_possible_target == original, TRUE, iter_possible_target == bumped))
			considering |= iter_possible_target
	if(length(considering))
		return pick(considering)
	// 4. objs and other dense things
	for(var/i in our_turf)
		if(can_hit_target(i, i == original, TRUE, i == bumped))
			considering += i
	if(length(considering))
		return pick(considering)
	// 5. turf
	if(can_hit_target(our_turf, our_turf == original, TRUE, our_turf == bumped))
		return our_turf
	// 6. nothing
		// (returns null)

/**
 * Returns true if the target atom is on our current turf and above the right layer
 * If direct target is true it's the originally clicked target.
 */
/obj/projectile/proc/can_hit_target(atom/target, direct_target = FALSE, ignore_loc = FALSE, cross_failed = FALSE)
	if(QDELETED(target) || impacted[target.weak_reference])
		return FALSE
	if(target == firer && !ignore_source_check)
		return FALSE
	if(!ignore_loc && (loc != target.loc) && !(can_hit_turfs && direct_target && loc == target))
		return FALSE
	// if pass_flags match, pass through entirely - unless direct target is set.
	if((target.pass_flags_self & pass_flags) && !direct_target)
		return FALSE
	if(HAS_TRAIT(target, TRAIT_UNHITTABLE_BY_PROJECTILES))
		if(!HAS_TRAIT(target, TRAIT_BLOCKING_PROJECTILES) && isliving(target))
			var/mob/living/living_target = target
			living_target.block_projectile_effects()
		return FALSE
	if(!ignore_source_check && firer && !direct_target)
		if(target == firer || (target == firer.loc && ismech(firer.loc)))
			return FALSE
	if(target.density || cross_failed) //This thing blocks projectiles, hit it regardless of layer/mob stuns/etc.
		return TRUE
	if(!isliving(target))
		if(isturf(target)) // non dense turfs
			return can_hit_turfs && direct_target
		if(target.layer < hit_threshhold)
			return FALSE
		else if(!direct_target) // non dense objects do not get hit unless specifically clicked
			return FALSE
	else
		var/mob/living/living_target = target
		if(direct_target)
			return TRUE
		if(living_target.stat == DEAD)
			return FALSE
	// 	if(HAS_TRAIT(living_target, TRAIT_IMMOBILIZED) && HAS_TRAIT(living_target, TRAIT_FLOORED) && HAS_TRAIT(living_target, TRAIT_HANDS_BLOCKED))
	// 		return FALSE
		if(hit_prone_targets)
			var/mob/living/buckled_to = living_target.lowest_buckled_mob()
			if((maximum_range - range) <= MAX_RANGE_HIT_PRONE_TARGETS) // after MAX_RANGE_HIT_PRONE_TARGETS tiles, auto-aim hit for mobs on the floor turns off
				return TRUE
			if(ignore_range_hit_prone_targets) // doesn't apply to projectiles that must hit the target in combat mode or something else, no matter what
				return TRUE
			if(buckled_to.density) // Will just be us if we're not buckled to another mob
				return TRUE
			return FALSE
	//	else if(living_target.body_position == LYING_DOWN)
		else if(living_target.lying)
			return FALSE
	return TRUE

/**
 * Scans if we should hit something on the turf we just moved to if we haven't already
 *
 * This proc is a little high in overhead but allows us to not snowflake CanPass in living and other things.
 */
/obj/projectile/proc/scan_moved_turf()
	// Optimally, we scan: mobs --> objs --> turf for impact
	// but, overhead is a thing and 2 for loops every time it moves is a no-go.
	// realistically, since we already do select_target in impact, we can not do that
	// and hope projectiles get refactored again in the future to have a less stupid impact detection system
	// that hopefully won't also involve a ton of overhead
	if(can_hit_target(original, TRUE, FALSE))
		impact(original) // try to hit thing clicked on
		return
	// else, try to hit mobs
	else // because if we impacted original and pierced we'll already have select target'd and hit everything else we should be hitting
		for(var/mob/M in loc) // so I guess we're STILL doing a for loop of mobs because living movement would otherwise have snowflake code for projectile CanPass
			// so the snowflake vs performance is pretty arguable here
			if(can_hit_target(M, M == original, TRUE))
				impact(M)
				break

/**
 * Projectile crossed: When something enters a projectile's tile, make sure the projectile hits it if it should be hitting it.
 */
/obj/projectile/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(can_hit_target(AM, direct_target = (AM == original)))
		impact(AM)

/**
 * Projectile can pass through
 * Used to not even attempt to Bump() or fail to Cross() anything we already hit.
 *
 * This was called CanPassThrough() on TG but we don't have it yet
 */
/obj/projectile/CanPass(atom/blocker, movement_dir, blocker_opinion)
	return ..() || impacted[blocker.weak_reference]

/**
 * Projectile moved:
 *
 * If not fired yet, do not do anything. Else,
 *
 * If temporary unstoppable movement used for piercing through things we already hit (impacted list) is set, unset it.
 * Scan turf we're now in for anything we can/should hit. This is useful for hitting non dense objects the user
 * directly clicks on, as well as for PHASING projectiles to be able to hit things at all as they don't ever Bump().
 */
/obj/projectile/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	if(!fired)
		return
	if(temporary_unstoppable_movement)
		temporary_unstoppable_movement = FALSE
		movement_type &= ~PHASING
	scan_moved_turf() //mostly used for making sure we can hit a non-dense object the user directly clicked on, and for penetrating projectiles that don't bump

/**
 * Checks if we should pierce something.
 *
 * NOT meant to be a pure proc, since this replaces prehit() which was used to do things.
 * Return PROJECTILE_DELETE_WITHOUT_HITTING to delete projectile without hitting at all!
 */
/obj/projectile/proc/prehit_pierce(atom/A)
	if((projectile_phasing & A.pass_flags_self) && (phasing_ignore_direct_target || original != A))
		return PROJECTILE_PIERCE_PHASE
	if(projectile_piercing & A.pass_flags_self)
		if (penetrating > pierces)
			if(prob(min(100, (pierce_chance + (damage/4) + armor_penetration) * anti_materiel_potential))) //Base pierce_chance is 0. This gives the STS a 30% chance to pierce once.
				damage *= pierce_decay_damage
				penetrating--
				last_hit_pierced = TRUE
				return PROJECTILE_PIERCE_HIT

	if(ismovable(A))
		var/atom/movable/AM = A
		if(AM.throwing)
			return (projectile_phasing & LETPASSTHROW) ? PROJECTILE_PIERCE_PHASE : ((projectile_piercing & LETPASSTHROW)? PROJECTILE_PIERCE_HIT : PROJECTILE_PIERCE_NONE)
	last_hit_pierced = FALSE
	return PROJECTILE_PIERCE_NONE

/obj/projectile/proc/check_ricochet(atom/A)
	var/chance = ricochet_chance * A.receive_ricochet_chance_mod
	if(firer && HAS_TRAIT(firer, TRAIT_NICE_SHOT))
		chance += NICE_SHOT_RICOCHET_BONUS
	if(ricochets < min_ricochets || prob(chance))
		return TRUE
	return FALSE

/obj/projectile/proc/check_ricochet_flag(atom/A)
	if((check_armor in list(ENERGY, LASER)) && (A.flags_ricochet & RICOCHET_SHINY))
		return TRUE

	if((check_armor in list(BOMB, BULLET)) && (A.flags_ricochet & RICOCHET_HARD))
		return TRUE

	return FALSE

/obj/projectile/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	return TRUE //Bullets don't drift in space

/obj/projectile/process()
	last_process = world.time
	if(!loc || !fired || !movement_vector)
		fired = FALSE
		return PROCESS_KILL

	// If last tick the projectile impacted something or reached its range, don't process it
	if (deletion_queued == PROJECTILE_IMPACT_DELETE)
		ticks_to_deletion -= 1
		if (!ticks_to_deletion)
			qdel(src)
		return

	if (deletion_queued == PROJECTILE_RANGE_DELETE)
		on_range()
		return

	if(paused || !isturf(loc))
		last_projectile_move = last_process //Compensates for pausing, so it doesn't become a hitscan projectile when unpaused from charged up ticks.
		return

	if (hitscan)
		process_hitscan()
		return

	var/elapsed_time = world.time - last_projectile_move
	var/pixels_to_move = elapsed_time * SSprojectiles.pixels_per_decisecond * speed + overrun
	overrun = 0

	if (pixels_to_move > SSprojectiles.max_pixels_per_tick)
		overrun = pixels_to_move - SSprojectiles.max_pixels_per_tick
		pixels_to_move = SSprojectiles.max_pixels_per_tick

	overrun += MODULUS(pixels_to_move, 1)
	pixels_to_move = FLOOR(pixels_to_move, 1)
	SEND_SIGNAL(src, COMSIG_PROJECTILE_BEFORE_MOVE)

	// Registering turf entries is done here instead of a connect_loc because else it could be called multiple times per tick and waste performance
	if (last_tick_turf)
		UnregisterSignal(last_tick_turf, COMSIG_ATOM_ENTERED)

	process_movement(pixels_to_move)

	if (!QDELETED(src) && !deletion_queued && isturf(loc))
		RegisterSignal(loc, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))
		last_tick_turf = loc

/*
 * Main projectile movement cycle.
 * Normal behavior moves projectiles in a straight line through tiles, but it gets trickier with homing.
 * Every pixels_per_decisecond we will stop and call process_homing(), which while a bit rough, does not have a significant performance impact
 * This proc needs to be very performant, so do not add overridable logic that can be handled in homing or animations here.
 * Return is how many tiles we've actually passed (or attempted to pass, if we ended up on a half-move)
 *
 * pixels_to_move determines how many pixels the projectile should move
 * hitscan prevents animation logic from running
 * tile_limit prevents any movements past the first tile change
 */
/obj/projectile/proc/process_movement(pixels_to_move, hitscan = FALSE, tile_limit = FALSE)
	if (!isturf(loc) || !movement_vector)
		return FALSE
	var/total_move_distance = pixels_to_move
	var/movements_done = 0
	last_projectile_move = world.time
	while (pixels_to_move > 0 && isturf(loc) && !QDELETED(src) && !deletion_queued)
		// Because pixel_x/y represents offset and not actual visual position of the projectile, we add 16 pixels to each and cut the excess because projectiles are not meant to be highly offset by default
		var/pixel_x_actual = pixel_x + ICON_SIZE_X / 2
		if(pixel_x_actual > ICON_SIZE_X)
			pixel_x_actual = pixel_x_actual % ICON_SIZE_X

		var/pixel_y_actual = pixel_y + ICON_SIZE_Y / 2
		if(pixel_y_actual > ICON_SIZE_Y)
			pixel_y_actual = pixel_y_actual % ICON_SIZE_Y

		var/distance_to_border = INFINITY
		// What distances do we need to move to hit the horizontal/vertical turf border
		var/x_to_border = INFINITY
		var/y_to_border = INFINITY
		// If we're moving strictly up/down/left/right then one of these can be 0 and produce div by zero
		if (movement_vector.pixel_x)
			var/x_border_dist = -pixel_x_actual
			if (movement_vector.pixel_x > 0)
				x_border_dist = ICON_SIZE_X - pixel_x_actual
			x_to_border = x_border_dist / movement_vector.pixel_x
			distance_to_border = x_to_border

		if (movement_vector.pixel_y)
			var/y_border_dist = -pixel_y_actual
			if (movement_vector.pixel_y > 0)
				y_border_dist = ICON_SIZE_Y - pixel_y_actual
			y_to_border = y_border_dist / movement_vector.pixel_y
			distance_to_border = min(distance_to_border, y_to_border)

		// Something went extremely wrong
		if (distance_to_border == INFINITY)
			stack_trace("WARNING: Projectile had an empty movement vector and tried to process")
			qdel(src)
			return movements_done

		var/distance_to_move = min(distance_to_border, pixels_to_move)
		// For homing we cap the maximum distance to move every loop
		if (homing && distance_to_move > SSprojectiles.pixels_per_decisecond)
			distance_to_move = SSprojectiles.pixels_per_decisecond

		// Figure out if we move to the next turf and if so, what its positioning relatively to us is
		var/x_shift = distance_to_move >= x_to_border ? SIGN(movement_vector.pixel_x) : 0
		var/y_shift = distance_to_move >= y_to_border ? SIGN(movement_vector.pixel_y) : 0
		var/moving_turfs = x_shift || y_shift
		// Calculate where in the turf we will be when we cross the edge.
		// This is a projectile variable because its also used in hit VFX
		entry_x = pixel_x + movement_vector.pixel_x * distance_to_move - x_shift * ICON_SIZE_X
		entry_y = pixel_y + movement_vector.pixel_y * distance_to_move - y_shift * ICON_SIZE_Y
		var/delete_distance = 0

		if (moving_turfs)
			var/turf/new_turf = locate(x + x_shift, y + y_shift, z)
			// We've hit an invalid turf, end of a z level or smth went wrong
			if (!istype(new_turf))
				qdel(src)
				return movements_done

			// Move to the next tile
			step_towards(src, new_turf)
			SEND_SIGNAL(src, COMSIG_PROJECTILE_MOVE_PROCESS_STEP)
			// We hit something and got deleted, stop the loop
			if (QDELETED(src))
				return movements_done
			if (loc != new_turf)
				moving_turfs = FALSE
			// If we've impacted something, we need to animate our movement until the actual hit
			// Otherwise the projectile visually disappears slightly before the actual impact
			// Not if we're hitscan, however, microop time!
			if (deletion_queued && !hitscan)
				// distance_to_move is how much we have to step to get to the next turf, hypotenuse is how much we need
				// to move in the next turf to get from entry to impact position
				delete_distance = distance_to_move + sqrt((impact_x - entry_x) ** 2 + (impact_y - entry_y) ** 2)

		movements_done += 1
		// We cannot move more than one turf worth of distance per loop, so this is a safe solution
		pixels_moved_last_tile += distance_to_move
		if (!deletion_queued && pixels_moved_last_tile >= ICON_SIZE_ALL)
			reduce_range()
			if (QDELETED(src))
				return movements_done
			// Similarly with range out deletion, need to calculate how many pixels we can actually move before deleting
			if (deletion_queued)
				delete_distance = distance_to_move - (ICON_SIZE_ALL - pixels_moved_last_tile)

		if (deletion_queued)
			// Hitscans don't need to wait before deleting
			if (hitscan)
				return movements_done

			// We moved to the next turf first, then impacted something
			// This means that we need to offset our visual position back to the previous turf, then figure out
			// how much we moved on the next turf (or we didn't move at all in which case we both shifts are 0 anyways)
			if (moving_turfs)
				pixel_x -= x_shift * ICON_SIZE_X
				pixel_y -= y_shift * ICON_SIZE_Y

			// Similarly to normal animate code, but use lowered deletion distance instead.
			var/delete_x = pixel_x + movement_vector.pixel_x * delete_distance
			var/delete_y = pixel_y + movement_vector.pixel_y * delete_distance
			// In order to keep a consistent speed, calculate at what point between ticks we get deleted
			var/animate_time = world.tick_lag * delete_distance / total_move_distance
			// Sometimes we need to move *just a bit* more than we can afford this tick - in this case, delete a tick after
			// so we don't disappear before impact. This shouldn't be more than 1, ever.
			if (delete_distance > pixels_to_move)
				ticks_to_deletion += 1
			// We can use animation chains to visually disappear between ticks.
			if (!move_animate(delete_x, delete_y, animate_time, deleting = TRUE))
				animate(src, pixel_x = delete_x, pixel_y = delete_y, time = animate_time, flags = ANIMATION_PARALLEL | ANIMATION_CONTINUE)
				animate(alpha = 0, time = 0, flags = ANIMATION_CONTINUE)
			return movements_done

		pixels_to_move -= distance_to_move
		// animate() instantly changes pixel_x/y values and just interpolates them client-side so next loop processes properly
		if (hitscan)
			pixel_x = entry_x
			pixel_y = entry_y
		else
			// We need to shift back to the tile we were on before moving
			pixel_x -= x_shift * ICON_SIZE_X
			pixel_y -= y_shift * ICON_SIZE_Y
			if (!move_animate(entry_x, entry_y))
				animate(src, pixel_x = entry_x, pixel_y = entry_y, time = world.tick_lag * distance_to_move / total_move_distance, flags = ANIMATION_PARALLEL | ANIMATION_CONTINUE)

		// Homing caps our movement speed per loop while leaving per tick speed intact, so we can just call process_homing every loop here
		if (homing)
			process_homing()

		// We've hit a timestop field, abort any remaining movement
		if (paused)
			return movements_done

		// Prevents long-range high-speed projectiles from ruining the server performance by moving 100 tiles per tick when subsystem is set to a high cap
		if (TICK_CHECK)
			// If we ran out of time, add whatever distance we're yet to pass to overrun debt to be processed next tick and break the loop
			overrun += pixels_to_move
			return movements_done

		if (tile_limit && moving_turfs)
			return movements_done

	return movements_done

/// Called every time projectile animates its movement, in case child wants to have custom animations.
/// Returning TRUE cancels normal animation
/obj/projectile/proc/move_animate(animate_x, animate_y, animate_time = world.tick_lag, deleting = FALSE)
	return FALSE

/obj/projectile/proc/fire(fire_angle, atom/direct_target)
	LAZYINITLIST(impacted)
	if(firer)
		RegisterSignal(firer, COMSIG_QDELETING, PROC_REF(firer_deleted))
		SEND_SIGNAL(firer, COMSIG_PROJECTILE_FIRER_BEFORE_FIRE, src, fired_from, original)
	if(fired_from)
		if (firer != fired_from)
			RegisterSignal(fired_from, COMSIG_QDELETING, PROC_REF(fired_from_deleted))
		SEND_SIGNAL(fired_from, COMSIG_PROJECTILE_BEFORE_FIRE, src, original)
	if (original)
		if (!firer != original)
			RegisterSignal(original, COMSIG_QDELETING, PROC_REF(original_deleted))
	if(!log_override && firer && original && !do_not_log)
		log_combat(firer, original, "fired at", src, "from [get_area_name(src, TRUE)]")
			//note: mecha projectile logging is handled in /obj/item/mecha_parts/mecha_equipment/weapon/action(). try to keep these messages roughly the sameish just for consistency's sake.
	var/atom/pb_target = direct_target || original
	if(pb_target && (get_dist(pb_target, get_turf(src)) == 0)) // point blank shots
		impact(pb_target)
		if(QDELETED(src))
			return
	var/turf/starting = get_turf(src)
	if(isnum(fire_angle))
		set_angle(fire_angle)
	else if(isnull(angle)) //Try to resolve through offsets if there's no angle set.
		if(isnull(xo) || isnull(yo))
			stack_trace("WARNING: Projectile [type] deleted due to being unable to resolve a target after angle was null!")
			qdel(src)
			return
		var/turf/target = locate(clamp(starting.x + xo, 1, world.maxx), clamp(starting.y + yo, 1, world.maxy), starting.z)
		set_angle(get_angle(src, target))
	if(spread)
		set_angle(angle + (rand() - 0.5) * spread)
	original_angle = angle
	movement_vector = new(speed, angle)
	if (hitscan)
		beam_points = list()
	free_hitscan_forceMove = TRUE
	forceMove(starting)
	last_projectile_move = world.time
	fired = TRUE
	// play_fov_effect(starting, 6, "gunfire", dir = NORTH, angle = Angle)
	SEND_SIGNAL(src, COMSIG_PROJECTILE_FIRE)
	if(hitscan && !deletion_queued)
		record_hitscan_start()
		process_hitscan()
		if(QDELETED(src))
			return
	if(!(datum_flags & DF_ISPROCESSING))
		START_PROCESSING(SSprojectiles, src)
	if (!deletion_queued && !hitscan)
		process_movement(max(FLOOR(speed, 1), 1), tile_limit = TRUE)


/obj/projectile/forceMove(atom/target)
	if (!hitscan || isnull(beam_points))
		return ..()
	create_hitscan_point()
	. = ..()
	if(!isturf(loc) || !isturf(target) || !z || QDELETED(src) || deletion_queued)
		return
	if (isnull(movement_vector) || free_hitscan_forceMove)
		return
	// Create firing VFX and start a new chain because we most likely got teleported
	generate_hitscan_tracers(impact_point = FALSE)
	original_angle = angle
	spawned_muzzle = FALSE
	record_hitscan_start(offset = FALSE)

/obj/projectile/proc/generate_hitscan_tracers(impact_point = TRUE, impact_visual = TRUE)
	if (!length(beam_points))
		return

	if (impact_point)
		create_hitscan_point(impact = TRUE)

	if (tracer_type)
		// Stores all turfs we've created light effects on, in order to not dupe them if we enter a reflector loop
		// Uses an assoc list for performance reasons
		var/list/passed_turfs = list()
		for (var/beam_point in beam_points)
			generate_tracer(beam_point, passed_turfs)

	if (muzzle_type && !spawned_muzzle)
		spawned_muzzle = TRUE
		var/datum/point/start_point = beam_points[1]
		var/atom/movable/muzzle_effect = new muzzle_type(loc)
		start_point.move_atom_to_src(muzzle_effect)
		var/matrix/matrix = new
		matrix.Turn(original_angle)
		muzzle_effect.transform = matrix
		muzzle_effect.color =  color
		muzzle_effect.set_light(muzzle_flash_range, muzzle_flash_intensity, muzzle_flash_color_override || color)
		QDEL_IN(muzzle_effect, PROJECTILE_TRACER_DURATION)

	if (impact_type && impact_visual)
		var/atom/movable/impact_effect = new impact_type(loc)
		last_point.move_atom_to_src(impact_effect)
		var/matrix/matrix = new
		matrix.Turn(angle)
		impact_effect.transform = matrix
		impact_effect.color =  color
		impact_effect.set_light(impact_light_range, impact_light_intensity, impact_light_color_override || color)
		QDEL_IN(impact_effect, PROJECTILE_TRACER_DURATION)

/obj/projectile/proc/generate_tracer(datum/point/start_point, list/passed_turfs)
	if (isnull(beam_points[start_point]))
		return

	var/datum/point/end_point = beam_points[start_point]
	var/datum/point/midpoint = point_midpoint_points(start_point, end_point)
	var/obj/effect/projectile/tracer/tracer_effect = new tracer_type(midpoint.return_turf())
	tracer_effect.apply_vars(
		angle_override = angle_between_points(start_point, end_point),
		p_x = midpoint.pixel_x,
		p_y = midpoint.pixel_y,
		color_override = color,
		scaling = pixel_length_between_points(start_point, end_point) / ICON_SIZE_ALL
	)
	tracer_effect.plane = GAME_PLANE

	QDEL_IN(tracer_effect, PROJECTILE_TRACER_DURATION)

	if (!hitscan_light_range || !hitscan_light_intensity)
		return

	var/list/turf/light_line = get_line(start_point.return_turf(), end_point.return_turf())
	for (var/turf/light_turf as anything in light_line)
		if (passed_turfs[light_turf])
			continue
		passed_turfs[light_turf] = TRUE
		//QDEL_IN(new /obj/effect/abstract/projectile_lighting(light_turf, hitscan_light_color_override || color, hitscan_light_range, hitscan_light_intensity), PROJECTILE_TRACER_DURATION)

/**
 * Aims the projectile at a target.
 *
 * Must be passed at least one of a target or a list of click parameters.
 * If only passed the click modifiers the source atom must be a mob with a client.
 *
 * Arguments:
 * - [target][/atom]: (Optional) The thing that the projectile will be aimed at.
 * - [source][/atom]: The initial location of the projectile or the thing firing it.
 * - [modifiers][/list]: (Optional) A list of click parameters to apply to this operation.
 * - deviation: (Optional) How the trajectory should deviate from the target in degrees.
 *   - //Spread is FORCED!
 */
/obj/projectile/proc/aim_projectile(atom/target, atom/source, list/modifiers = null, deviation = 0)
	if(!(isnull(modifiers) || islist(modifiers)))
		stack_trace("WARNING: Projectile [type] fired with non-list modifiers, likely was passed click params. Modifiers were the following: [modifiers]")
		modifiers = null

	var/turf/source_loc = get_turf(source)
	var/turf/target_loc = get_turf(target)

	if(isnull(source_loc))
		stack_trace("WARNING: Projectile [type] fired from nullspace.")
		qdel(src)
		return FALSE

	if(fired)
		stack_trace("WARNING: Projectile [type] was aimed after already being fired.")
		qdel(src)
		return FALSE

	free_hitscan_forceMove = TRUE
	forceMove(source_loc)
	starting = source_loc
	pixel_x = source.pixel_x
	pixel_y = source.pixel_y
	original = target

	// Trim off excess pixel_x/y by converting them into turf offset
	if (abs(pixel_x) > ICON_SIZE_X / 2)
		for (var/i in 1 to floor(abs(pixel_x) + ICON_SIZE_X / 2) / ICON_SIZE_X)
			var/turf/new_loc = get_step(source_loc, pixel_x > 0 ? EAST : WEST)
			if (!istype(new_loc))
				break
			source_loc = new_loc
		pixel_x = pixel_x % (ICON_SIZE_X / 2)

	if (abs(pixel_y) > ICON_SIZE_Y / 2)
		for (var/i in 1 to floor(abs(pixel_y) + ICON_SIZE_Y / 2) / ICON_SIZE_Y)
			var/turf/new_loc = get_step(source_loc, pixel_y > 0 ? NORTH : SOUTH)
			if (!istype(new_loc))
				break
			source_loc = new_loc
		pixel_y = pixel_y % (ICON_SIZE_X / 2)

	// We've got moved by turf offsets
	if (starting != source_loc)
		starting = source_loc
		forceMove(source_loc)

	if(length(modifiers))
		var/list/calculated = calculate_projectile_angle_and_pixel_offsets(source, target_loc && target, modifiers)
		p_x = calculated[2]
		p_y = calculated[3]
		set_angle(calculated[1] + deviation)
		return TRUE

	if(target_loc)
		yo = target_loc.y - source_loc.y
		xo = target_loc.x - source_loc.x
		if(target_loc == source_loc)
			set_angle(dir2angle(source_position.dir) + deviation)
		else
			set_angle(get_angle(src, target_loc) + deviation)
		return TRUE

	stack_trace("WARNING: Projectile [type] fired without a target or mouse parameters to aim with.")
	qdel(src)
	return FALSE

/obj/projectile/proc/after_z_change(atom/olcloc, atom/newloc)

/obj/projectile/proc/before_z_change(turf/oldloc, turf/newloc)

/obj/projectile/vv_edit_var(var_name, var_value)
	if(var_name == NAMEOF(src, angle))
		set_angle(var_value)
		return TRUE
	return ..()

/obj/projectile/proc/record_hitscan_start(offset = TRUE)
	if (isnull(beam_points))
		beam_points = list()
	else
		QDEL_LIST_ASSOC(beam_points)
		QDEL_NULL(last_point)
	last_point = RETURN_PRECISE_POINT(src)
	// If moving, increment its position a bit to prevent it from looking like its coming from firer's ass
	if (offset && !isnull(movement_vector))
		last_point.increment(movement_vector.pixel_x * MUZZLE_EFFECT_PIXEL_INCREMENT, movement_vector.pixel_y * MUZZLE_EFFECT_PIXEL_INCREMENT)
	beam_points[last_point] = null

/// Creates a new keypoint in which the tracer will split
/obj/projectile/proc/create_hitscan_point(impact = FALSE, tile_center = FALSE, broken_segment = FALSE)
	var/atom/handle_atom = last_impact_turf || src
	var/atom/used_point = tile_center ? loc : src
	var/datum/point/new_point = impact ? new /datum/point(handle_atom.x, handle_atom.y, handle_atom.z, impact_x, impact_y) : RETURN_PRECISE_POINT(used_point)
	if (!broken_segment)
		beam_points[last_point] = new_point
	beam_points[new_point] = null
	last_point = new_point

/obj/projectile/proc/process_hitscan()
	if (isnull(movement_vector))
		qdel(src)
		return

	while (isturf(loc) && !QDELETED(src))
		process_movement(ICON_SIZE_ALL, hitscan = TRUE)

		if (QDELETED(src))
			return

		if (!TICK_CHECK && !paused)
			continue

		create_hitscan_point()
		// Create tracers if we get timestopped or lagchunk so there aren't weird delays
		generate_hitscan_tracers(impact_point = FALSE, impact_visual = FALSE)
		record_hitscan_start(offset = FALSE)
		return

/obj/projectile/proc/process_homing() //may need speeding up in the future performance wise.
	if(!homing_target)
		return
	var/datum/point/new_point = RETURN_PRECISE_POINT(homing_target)
	new_point.pixel_x += homing_offset_x
	new_point.pixel_y += homing_offset_y
	var/new_angle = closer_angle_difference(angle, angle_between_points(RETURN_PRECISE_POINT(src), new_point))
	set_angle(angle + clamp(new_angle, -homing_turn_speed, homing_turn_speed))

/obj/projectile/proc/set_homing_target(atom/A)
	if(!A || (!isturf(A) && !isturf(A.loc)))
		return FALSE
	homing = TRUE
	homing_target = A
	homing_offset_x = rand(homing_inaccuracy_min, homing_inaccuracy_max)
	homing_offset_y = rand(homing_inaccuracy_min, homing_inaccuracy_max)
	if(prob(50))
		homing_offset_x = -homing_offset_x
	if(prob(50))
		homing_offset_y = -homing_offset_y

/**
 * Calculates the pixel offsets and angle that a projectile should be launched at.
 *
 * Arguments:
 * - [source][/atom]: The thing that the projectile is being shot from.
 * - [target][/atom]: (Optional) The thing that the projectile is being shot at.
 *   - If this is not provided the  source atom must be a mob with a client.
 * - [modifiers][/list]: A list of click parameters used to modify the shot angle.
 */
/proc/calculate_projectile_angle_and_pixel_offsets(atom/source, atom/target, modifiers)
	var/angle = 0
	var/p_x = LAZYACCESS(modifiers, ICON_X) ? text2num(LAZYACCESS(modifiers, ICON_X)) : ICON_SIZE_X / 2 // ICON_(X|Y) are measured from the bottom left corner of the icon.
	var/p_y = LAZYACCESS(modifiers, ICON_Y) ? text2num(LAZYACCESS(modifiers, ICON_Y)) : ICON_SIZE_Y / 2 // This centers the target if modifiers aren't passed.

	if(target)
		var/turf/source_loc = get_turf(source)
		var/turf/target_loc = get_turf(target)
		var/dx = ((target_loc.x - source_loc.x) * ICON_SIZE_X) + (target.pixel_x - source.pixel_x) + (p_x - (ICON_SIZE_X / 2))
		var/dy = ((target_loc.y - source_loc.y) * ICON_SIZE_Y) + (target.pixel_y - source.pixel_y) + (p_y - (ICON_SIZE_Y / 2))
		if(!dx && !dy)
			angle = dir2angle(source.dir)
		else
			angle = ATAN2(dy, dx)
		return list(angle, p_x, p_y)

	if(!ismob(source) || !LAZYACCESS(modifiers, SCREEN_LOC))
		CRASH("Can't make trajectory calculations without a target or click modifiers and a client.")

	var/mob/user = source
	if(!user.client)
		CRASH("Can't make trajectory calculations without a target or click modifiers and a client.")

	/// Split screen-loc up into X+Pixel_X and Y+Pixel_Y
	var/list/screen_loc_params = splittext(LAZYACCESS(modifiers, SCREEN_LOC), ",")
	/// Split X+Pixel_X up into list(X, Pixel_X)
	var/list/screen_loc_X = splittext(screen_loc_params[1],":")
	/// Split Y+Pixel_Y up into list(Y, Pixel_Y)
	var/list/screen_loc_Y = splittext(screen_loc_params[2],":")

	var/tx = (text2num(screen_loc_X[1]) - 1) * ICON_SIZE_X + text2num(screen_loc_X[2])
	var/ty = (text2num(screen_loc_Y[1]) - 1) * ICON_SIZE_Y + text2num(screen_loc_Y[2])

	/// Calculate the "resolution" of screen based on client's view and world's icon size. This will work if the user can view more tiles than average.
	var/list/screenview = view_to_pixels(user.client.view)

	var/ox = round(screenview[1] / 2) - user.client.pixel_x //"origin" x
	var/oy = round(screenview[2] / 2) - user.client.pixel_y //"origin" y
	angle = ATAN2(tx - oy, ty - ox)
	return list(angle, p_x, p_y)

/// Reflects the projectile off of something
/obj/projectile/proc/reflect(atom/hit_atom)
	if(!starting)
		return
	var/new_x = starting.x + pick(0, 0, 0, 0, 0, -1, 1, -2, 2)
	var/new_y = starting.y + pick(0, 0, 0, 0, 0, -1, 1, -2, 2)
	var/turf/current_tile = get_turf(hit_atom)

	// redirect the projectile
	original = locate(new_x, new_y, z)
	starting = current_tile
	firer = hit_atom
	yo = new_y - current_tile.y
	xo = new_x - current_tile.x
	var/new_angle_s = angle + rand(120,240)
	while(new_angle_s > 180) // Translate to regular projectile degrees
		new_angle_s -= 360
	set_angle(new_angle_s)

/// Fire a projectile from this atom at another atom
/atom/proc/fire_projectile(projectile_type, atom/target, sound, firer, list/ignore_targets = list())
	if (!isnull(sound))
		playsound(src, sound, vol = 100, vary = TRUE)

	var/turf/startloc = get_turf(src)
	var/obj/projectile/bullet = new projectile_type(startloc)
	bullet.starting = startloc
	for (var/atom/thing as anything in ignore_targets)
		bullet.impacted[WEAKREF(thing)] = TRUE
	bullet.firer = firer || src
	bullet.fired_from = src
	bullet.yo = target.y - startloc.y
	bullet.xo = target.x - startloc.x
	bullet.original = target
	bullet.aim_projectile(target, src)
	bullet.fire()

	return bullet


/*##############################
	AURORA SNOWFLAKE SECTION
##############################*/

/// Checks if the projectile is eligible for embedding. Not that it necessarily will.
/obj/projectile/proc/can_embed()
	//embed must be enabled and damage type must be brute
	if (projectile_piercing & PASSMOB) //If the shot passes through you it can't embed.
		if (last_hit_pierced)
			return FALSE
	if(!embed || damage_type != DAMAGE_BRUTE)
		return FALSE
	return TRUE

/obj/projectile/ex_act(var/severity = 2.0)
	return //explosions probably shouldn't delete projectiles

/obj/projectile/damage_flags()
	return damage_flags

/obj/projectile/proc/get_structure_damage()
	if(damage_type == DAMAGE_BRUTE || damage_type == DAMAGE_BURN)
		return damage * anti_materiel_potential
	return FALSE

/// Because I don't want to rewrite half the world to use embed_data just yet, this is left as is, praise be the omnissiah
/obj/projectile/proc/do_embed(var/obj/item/organ/external/organ)
	var/obj/item/SP = new shrapnel_type(organ)
	SP.edge = TRUE
	SP.sharp = TRUE
	SP.name = (name != "shrapnel") ? "[initial(name)] shrapnel" : "shrapnel"
	SP.desc += " It looks like it was fired from [fired_from]."
	SP.forceMove(organ)
	organ.embed(SP)
	return SP

/// wrapper for overrides.
/obj/projectile/set_angle(new_angle)
	if (angle == new_angle)
		return
	if(!nondirectional_sprite)
		transform = transform.TurnTo(angle, new_angle + projectile_angle)
	angle = new_angle
	if(movement_vector)
		movement_vector.set_angle(new_angle)
	if(fired && hitscan && isturf(loc))
		create_hitscan_point()

/// Same as set_angle, but the reflection continues from the center of the object that reflects it instead of the side
/obj/projectile/proc/set_angle_centered(center_turf, new_angle)
	if (angle == new_angle)
		return
	if(!nondirectional_sprite)
		transform = transform.TurnTo(angle, new_angle + projectile_angle)
	free_hitscan_forceMove = TRUE
	forceMove(center_turf)
	entry_x = 0
	entry_y = 0
	angle = new_angle
	if(movement_vector)
		movement_vector.set_angle(new_angle)
	if(fired && hitscan && isturf(loc))
		create_hitscan_point(tile_center = TRUE)

/obj/projectile/proc/get_print_info()
	. = "<br>"
	. += "Damage: [initial(damage)]<br>"
	. += "Damage Type: [initial(damage_type)]<br>"
	. += "Blocked by Armor Type: [initial(check_armor)]<br>"
	. += "Stuns: [initial(stun) ? "true" : "false"]<br>"
	if(initial(shrapnel_type))
		var/obj/shrapnel = new shrapnel_type
		. += "Shrapnel Type: [shrapnel.name]<br>"
	. += "Armor Penetration: [initial(armor_penetration)]%<br>"

/// This is where the bullet bounces off.
/atom/proc/bullet_ping(obj/projectile/P, var/pixel_x_offset, var/pixel_y_offset)
	if(!P || !P.ping_effect)
		return

	var/image/I = image('icons/obj/projectiles.dmi', src, P.ping_effect, 10, pixel_x = pixel_x_offset, pixel_y = pixel_y_offset)
	var/angle = (P.firer && prob(60)) ? round(get_angle(P.firer,src)) : round(rand(1,359))
	I.pixel_x += rand(-6,6)
	I.pixel_y += rand(-6,6)

	var/matrix/rotate = matrix()
	rotate.Turn(angle)
	I.transform = rotate
	// Need to do this in order to prevent the ping from being deleted
	playsound(src, P.get_structure_damage_sound(), P.vol_by_damage())
	addtimer(CALLBACK(I, TYPE_PROC_REF(/image, flick_overlay), src, 3), 1)

/image/proc/flick_overlay(var/atom/A, var/duration)
	A.overlays.Add(src)
	addtimer(CALLBACK(src, PROC_REF(flick_remove_overlay), A), duration)

/image/proc/flick_remove_overlay(var/atom/A)
	if(A)
		A.overlays.Remove(src)

#undef MOVES_HITSCAN
#undef MUZZLE_EFFECT_PIXEL_INCREMENT
#undef MAX_RANGE_HIT_PRONE_TARGETS
