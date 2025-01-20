extends Resource
class_name Phase

enum m { #PHASE MOVEMENT
	STILL, #stays still, define whether or not to move to a position first
	ROAM, #moves around randomly, define speed
	DASH, #moves to one position via tweening, define the position (possible to target player)
	TELEPORT, #moves to defined positions instantaneously, define positions (or just random)
	CIRCUIT, #moves to defined positions in order, define positions
	FOLLOW, #moves to a moving position (player), define speed
	RUN, #moves away from a moving position (player), define speed
}

enum a { #PHASE ATTACK PATTERN
	NOTHING, #won't attack
	CIRCLE, #spawns attacks in a circle around position, define position (can be game object), define radius
	LINE, #spawns attacks down defined vectors, define vectors (can originate from game object), define line length
	FOCUS, #spawns x number of attacks on a game object, define game object
	CHESS, #spawns attack in a chess pattern around a position
	BIGONE, #spawn "big" attacks somewhere, define positions (can't be game object)
}
#attacks multiple attack settings can be set

enum s { #PHASE SPECIAL
	NONE, #no special
	PULL, #pulls players towards position, define position (can be game object)
	PUSH, #pushes players away from a position, define position (can be game object)
	SPIN, #???
}

enum c { #PHASE CONDITION
	NORMAL, #all attacks validate no status is inflicted
	LIGHT_ONLY, #only light attacks validate
	HEAVY_ONLY, #only heavy attacks validate
	INVULNERABLE, #no attacks validate, status damage still applies
	INFLICT, #attacks will inflict status
	CLUTCH, #attacks deal more damage (check weapon)
}

enum r { #PHASE REACTION (what to do when something happens (on heavy attack, on light attack, on afflict, on close distance (phase defines), on half, on far distance (phase defines))
	NONE,
	RANDOM_PHASE, #switches to another phase the monster has
	SET_PHASE, #switches to a sub phase contained within
	CALL_OPTIONS,
}

#@export_group("Main Options","PHASE")
#@export var PHASE_MOVEMENT : m = m.STILL
#@export var PHASE_MAIN_ATTACK : a = a.NOTHING
#@export var PHASE_SUB_ATTACK : Array[a] = []
#@export var PHASE_SPECIAL : s = s.NONE
#@export var PHASE_CONDITION : c = c.NORMAL

@export var MOVEMENT_OPTIONS : Array[phaseMovementOption] = []
@export var ATTACK_OPTIONS : Array[phaseAttackOption] = []
@export var SUB_ATTACK_OPTIONS : int
@export var SPECIAL_OPTIONS : int
@export var CONDITION_OPTIONS : Array[phaseConditionOption] = []

var is_active := false

#phase order MOVE -> ATTACK or ATTACK -> MOVE

func setup():
	for a in ATTACK_OPTIONS: 
		a.my_phase = self
