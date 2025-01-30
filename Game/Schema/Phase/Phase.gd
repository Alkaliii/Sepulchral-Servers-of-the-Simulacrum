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
	SET_PHASE, #switches to a set idx
	ROLLBACK, #moves to earlier part of phase (on a good day, it's random as shit lol)
}

#@export_group("Main Options","PHASE")
#@export var PHASE_MOVEMENT : m = m.STILL
#@export var PHASE_MAIN_ATTACK : a = a.NOTHING
#@export var PHASE_SUB_ATTACK : Array[a] = []
#@export var PHASE_SPECIAL : s = s.NONE
#@export var PHASE_CONDITION : c = c.NORMAL

enum ord {
	MOVE, #picks a random movement option and performs it
	ATTACK, #picks a random attack option and performs it
	SUB_ATTACK, #picks a random sub attack option and performs it, will move onto next step after start
	SPECIAL, #picks a random special option and performs it
	WAIT, #waits
}

@export var schedule : Array[ord] = [ord.MOVE,ord.SPECIAL,ord.SUB_ATTACK,ord.ATTACK,ord.WAIT]
@export var on_heavy : r = r.NONE
@export var on_end : r = r.NONE #will repeat
@export var chance_to_stop : float = 0
## on heavy set phase idx
@export var ohspi : int = -1
## on end set phase idx
@export var oespi : int = -1
@export var wait_range : Vector2 = Vector2(0.5,2.0)

@export var MOVEMENT_OPTIONS : Array[phaseMovementOption] = []
@export var ATTACK_OPTIONS : Array[phaseAttackOption] = []
@export var SUB_ATTACK_OPTIONS : Array[phaseAttackOption] = []
@export var SPECIAL_OPTIONS : Array[phaseSpecialOption] = [] #only one is performed at a time?
@export var CONDITION_OPTIONS : Array[phaseConditionOption] = []

var is_active := false
var last_phase_action := false
var my_monster : system_monster_controller

#phase order MOVE -> ATTACK or ATTACK -> MOVE

var phase_idx : int = 0
var cur_option = null

func setup(mos : system_monster_controller):
	my_monster = mos
	for atk in ATTACK_OPTIONS: 
		atk.my_phase = self
	for atk in SUB_ATTACK_OPTIONS:
		atk.my_phase = self
	for mve in MOVEMENT_OPTIONS:
		mve.my_phase = self
	
	for sc in schedule:
		match sc:
			ord.MOVE:
				if MOVEMENT_OPTIONS.is_empty(): schedule.erase(sc)
			ord.ATTACK:
				if ATTACK_OPTIONS.is_empty(): schedule.erase(sc)
			ord.SUB_ATTACK:
				if SUB_ATTACK_OPTIONS.is_empty(): schedule.erase(sc)
			ord.SPECIAL:
				if SPECIAL_OPTIONS.is_empty(): schedule.erase(sc)

func clean_actions():
	for atk in ATTACK_OPTIONS:
		atk.cancel = false
	for atk in SUB_ATTACK_OPTIONS:
		atk.cancel = false
	for spc in SPECIAL_OPTIONS:
		spc.cancel = false

func kill_phase():
	#arbitrarirly stop a phase
	cancel = true
	#cancel current phase
	dconr(cur_option)
	if cur_option is phaseMovementOption:
		cancel_movement()
	if cur_option is phaseSpecialOption:
		cur_option.cancel = true
	if cur_option is phaseAttackOption:
		cur_option.cancel = true
	
	is_active = false

func play_phase(retrn = null):
	print("last phase finished!")
	if retrn: dconr(retrn)
	if cancel or !is_active: return
	if my_monster.dead: return
	if my_monster.active_phase != self:
		is_active = false
		return
	
	if phase_idx == 0 and last_phase_action: # last, perform on end
		match on_end:
			r.NONE:
				if randf_range(0,100) < chance_to_stop:
					kill_phase()
					my_monster.change_phase()
					return
			r.RANDOM_PHASE:
				kill_phase()
				my_monster.change_phase()
				return
			r.SET_PHASE:
				kill_phase()
				my_monster.change_phase(oespi)
				return
			r.ROLLBACK:
				phase_idx = 0
	
	match schedule[phase_idx]:
		ord.MOVE:
			pMOVE()
		ord.ATTACK:
			pATTACK()
		ord.SUB_ATTACK:
			pSUBATTACK()
		ord.SPECIAL:
			pSPECIAL()
		ord.WAIT:
			pWAIT()
	
	if phase_idx == (schedule.size() - 1):
		print("LAST ACTION")
		last_phase_action = true
	phase_idx = (phase_idx + 1) % schedule.size()

func dconr(retrn = null):
	if retrn is phaseMovementOption:
		if retrn.movement_complete.is_connected(play_phase):
			retrn.movement_complete.disconnect(play_phase)
	if retrn is phaseAttackOption:
		if retrn.attack_started.is_connected(play_phase):
			retrn.attack_started.disconnect(play_phase)
		if retrn.attack_complete.is_connected(play_phase):
			retrn.attack_complete.disconnect(play_phase)
	if retrn is phaseSpecialOption:
		if retrn.special_complete.is_connected(play_phase):
			retrn.special_complete.disconnect(play_phase)

func pWAIT(cwt : float = 0.0):
	if my_monster.dead: return
	cur_option = null
	var wait_time = randf_range(wait_range.x,wait_range.y)
	if cwt != 0.0: wait_time = clamp(cwt,0.0,3.0)
	print("I'M WAITIN! ", wait_time)
	while true:
		if wait_time <= 0: break
		if cancel: return
		wait_time -= App.get_process_delta_time()
		await App.process_frame()
	
	play_phase()

func pMOVE():
	if my_monster.dead: return
	if MOVEMENT_OPTIONS.is_empty():
		schedule.erase(ord.MOVE)
		play_phase()
		return
	var mve : phaseMovementOption = MOVEMENT_OPTIONS.pick_random()
	mve.movement_complete.connect(play_phase)
	mve.move(my_monster)
	print("I'M MOVIN! ", phase_idx)
	cur_option = mve

func pATTACK():
	if my_monster.dead: return
	if ATTACK_OPTIONS.is_empty():
		schedule.erase(ord.ATTACK)
		play_phase()
		return
	var atk : phaseAttackOption = ATTACK_OPTIONS.pick_random()
	atk.attack_complete.connect(play_phase)
	atk.attack(my_monster)
	print("I'M ATTACKIN! ", phase_idx)
	if atk.cancel: print("CANCELLED")
	cur_option = atk

func pSUBATTACK():
	if my_monster.dead: return
	if SUB_ATTACK_OPTIONS.is_empty():
		schedule.erase(ord.SUB_ATTACK)
		play_phase()
		return
	var satk : phaseAttackOption = SUB_ATTACK_OPTIONS.pick_random()
	satk.attack_started.connect(play_phase)
	satk.attack(my_monster)
	print("I'M ATTACKIN AGAIN! ", phase_idx)
	if satk.cancel: print("CANCELLED")
	cur_option = satk

func pSPECIAL():
	if my_monster.dead: return
	if SPECIAL_OPTIONS.is_empty():
		schedule.erase(ord.SPECIAL)
		play_phase()
		return
	print("I'M DOING SOMETHIN! ", phase_idx)
	var spc : phaseSpecialOption = SPECIAL_OPTIONS.pick_random()
	spc.special_complete.connect(play_phase)
	spc.perform_special(my_monster)
	if spc.cancel: print("CANCELLED")
	cur_option = spc

var cancel := false
func on_heavy_received():
	if cancel or !is_active: return
	cancel = true
	#cancel current phase
	dconr(cur_option)
	if cur_option is phaseMovementOption:
		cancel_movement()
	if cur_option is phaseSpecialOption:
		cur_option.cancel = true
	if cur_option is phaseAttackOption:
		cur_option.cancel = true
	
	#do on heavy action
	print("HEAVY!")
	await App.time_delay(0.25)
	match on_heavy:
		r.NONE:
			cancel = false
			play_phase()
		r.RANDOM_PHASE:
			kill_phase()
			my_monster.change_phase()
		r.SET_PHASE:
			kill_phase()
			my_monster.change_phase(ohspi)
		r.ROLLBACK:
			cancel = false
			var ps = schedule.duplicate()
			ps.erase(schedule[phase_idx])
			phase_idx = schedule.find(ps.pick_random())
			play_phase()

func cancel_movement(caller = null):
	for mve in MOVEMENT_OPTIONS:
		if mve == caller: continue
		mve.cancel_movement()

func validate_damage(click : int) -> bool:
	for con in CONDITION_OPTIONS:
		if !con.validate_on_condition(click):
			return false
	return true
