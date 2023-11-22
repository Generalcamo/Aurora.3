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

//Gun Bolt Types
/**
 * Gun has a bolt, it stays closed while not cycling. The gun must be racked to have a bullet chambered when a mag is inserted.
 * e.g: Shotguns, Bolt-Actions, Lever-Actions
 */
#define BOLT_TYPE_STANDARD 1
#define BOLT_TYPE_OPEN 2
#define BOLT_TYPE_NO_BOLT 3
#define BOLT_TYPE_LOCKING 4
