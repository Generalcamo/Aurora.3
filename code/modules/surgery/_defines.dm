#define SURGERY_FAILURE -1

// organ open flags
#define ORGAN_CLOSED            0
#define ORGAN_OPEN     1 // skin incision OR hatch unscrewed
#define ORGAN_RETRACTED    2 // skin retracted
#define ORGAN_ENCASED      3 // bones e.g. ribcage sawed open

#define ORGAN_OPEN_INCISION 1
#define ORGAN_OPEN_RETRACTED 2
#define ORGAN_ENCASED_OPEN 2.5
#define ORGAN_ENCASED_RETRACTED 3

// facial surgery
#define FACE_NORMAL             0
#define FACE_CUT_OPEN           1
#define FACE_RETRACTED          2
#define FACE_ALTERED            3

//bone repair
#define BONE_PRE_OP             0
#define BONE_GLUED              1
#define BONE_SET                2

//cavity
#define CAVITY_CLOSED           0
#define CAVITY_OPEN             1

//macros
#define IS_ORGAN_FULLY_OPEN affected.open == ((affected.encased || affected.robotic) ? ORGAN_ENCASED : ORGAN_RETRACTED)

#define SURGERY_NO_ROBOTIC BITFLAG(1)
#define SURGERY_NO_STUMP BITFLAG(2)
#define SURGERY_NEEDS_INCISION BITFLAG(3)
#define SURGERY_NEEDS_RETRACTED BITFLAG(4)
#define SURGERY_NEEDS_ENCASEMENT BITFLAG(5)
