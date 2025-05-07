#define ORGAN_CAN_FEEL_PAIN(organ) !BP_IS_ROBOTIC(organ) && (!organ.species || !(organ.species.flags & NO_PAIN))
#define ORGAN_IS_DISLOCATED(organ) (organ.dislocated > 0)
#define SOCKET_UNSHIELDED 0
#define SOCKET_SHIELDED 1
#define SOCKET_FULLSHIELDED 2

// organ open flags
#define ORGAN_CLOSED            0
#define ORGAN_OPEN     1 // skin incision OR hatch unscrewed
#define ORGAN_RETRACTED    2 // skin retracted
#define ORGAN_ENCASED      3 // bones e.g. ribcage sawed open

// Robotics hatch_state defines.
#define HATCH_CLOSED 0
#define HATCH_UNSCREWED 1
#define HATCH_OPENED 2
