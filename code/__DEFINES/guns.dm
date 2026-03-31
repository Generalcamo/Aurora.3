#define BULLET_IMPACT_NONE  "none"
#define BULLET_IMPACT_METAL "metal"
#define BULLET_IMPACT_MEAT  "meat"

#define SOUNDS_BULLET_MEAT  list('sound/effects/projectile_impact/bullet_meat1.ogg', 'sound/effects/projectile_impact/bullet_meat2.ogg', 'sound/effects/projectile_impact/bullet_meat3.ogg', 'sound/effects/projectile_impact/bullet_meat4.ogg')
#define SOUNDS_BULLET_METAL  list('sound/effects/projectile_impact/bullet_metal1.ogg', 'sound/effects/projectile_impact/bullet_metal2.ogg', 'sound/effects/projectile_impact/bullet_metal3.ogg')
#define SOUNDS_LASER_MEAT  list('sound/effects/projectile_impact/energy_meat1.ogg','sound/effects/projectile_impact/energy_meat2.ogg')
#define SOUNDS_LASER_METAL  list('sound/effects/projectile_impact/energy_metal1.ogg','sound/effects/projectile_impact/energy_metal2.ogg')
#define SOUNDS_ION_ANY      list('sound/effects/projectile_impact/ion_any.ogg')

//Used in determining the currently permissable firemodes of wireless-control firing pins.
#define WIRELESS_PIN_DISABLED  1
#define WIRELESS_PIN_AUTOMATIC 2
#define WIRELESS_PIN_STUN      3
#define WIRELESS_PIN_LETHAL    4

//RCD Modes (TODO: Have the other RCD types have defines and set them here.)
#define RFD_FLOORS_AND_WALL 1
#define RFD_WINDOW_AND_FRAME 2
#define RFD_AIRLOCK 3
#define RFD_DECONSTRUCT 4

//Ammo defines for gun/projectile related things.
//ammo_behavior_flags
///Ammo will impact a targeted open turf instead of continuing past it
#define AMMO_TARGET_TURF (1<<0)
// (1<<1) is unused
// (1<<2) is unused
///Ammo will pass through windows
#define AMMO_ENERGY (1<<3)
///Ammo is more likely to continue past cover such as cades
#define AMMO_BETTER_COVER_RNG (1<<4)
///Ammo will attempt to add firestacks and ignite a hit mob if it deals any damage. Armor applies, regardless of AMMO_IGNORE_ARMOR
#define AMMO_INCENDIARY (1<<5)
// (1<<6) is unused
///Generates blood splatters on mob hit
#define AMMO_BALLISTIC (1<<7)
///Ammo processes while traveling
#define AMMO_SPECIAL_PROCESS (1<<8)
// (1<<9) is unused
///Used to identify ammo that have intrinsic IFF properties
#define AMMO_IFF (1<<10)
///If the projectile from this ammo is hitscan
#define AMMO_HITSCAN (1<<11)
///If the projectile does something with on_leave_turf()
#define AMMO_LEAVE_TURF (1<<12)
///If the projectile passes through walls causing damage to them
#define AMMO_PASS_THROUGH_TURF (1<<13)
///If the projectile passes through mobs and objects causing damage to them
#define AMMO_PASS_THROUGH_MOVABLE (1<<14)
///If the projectile passes through mobs only causing damage to them
#define AMMO_PASS_THROUGH_MOB (1<<15)
///If the projectile ricochet and miss sound is pitched up
#define AMMO_SOUND_PITCH (1<<16)
// (1<<17) is unused
///Ammo type entirely ignores zombies
#define AMMO_SKIPS_ZOMBIE (1<<18)

//Gun bolt types
///Gun has a bolt, it stays closed while not cycling. The gun must be racked to have a bullet chambered when a mag is inserted.
/// Example: shotguns
#define BOLT_TYPE_STANDARD 1
///Gun has a bolt, it is open when ready to fire. The gun can never have a chambered bullet with no magazine, but the bolt stays ready when a mag is removed.
/// Example: Some SMGs, the L6
#define BOLT_TYPE_OPEN 2
///Gun has no moving bolt mechanism, it cannot be racked. Also dumps the entire contents when emptied instead of a magazine.
/// Example: Break action shotguns, revolvers
#define BOLT_TYPE_NO_BOLT 3
///Gun has a bolt, it locks back when empty. It can be released to chamber a round if a magazine is in.
/// Example: Pistols with a slide lock, some SMGs
#define BOLT_TYPE_LOCKING 4
///Gun has an HK-style locking charging handle, so you can slap it. Only use this for flavor, otherwise modern-style automatics should use BOLT_TYPE_LOCKING.
/// Example: everything made by lanchester
#define BOLT_TYPE_CLIP 5

//Overheat type
///Overheating will prevent the gun from working anymore. Most guns will use this
#define OVERHEAT_HALT 1
///Overheating will dump extra heat into an attached heatsink if available. For energy weapons. FUTURE USE
#define OVERHEAT_DUMP 2
