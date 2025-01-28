extends Resource
class_name system_status

enum effects {
	NONE, #NA
	STUN, #BAD, Stops entity from moving and forces them to do nothing for 1 secs (X icon)
	DOT, #BAD, Deals 1 damage every second for a period of time (broken heart icon)
	FEAR, #BAD, No weapon bonus (radial wiggly lines icon)
	WEAK, #BAD, Attacks deal half damage (ceil) (down arrow)
	MUTE, #BAD, Can't click self or others for aid, can't send msgs either (chat bubble with cross in it icon)
	BLIND, #BAD, Screen goes black (eye with no pupil icon)
	SICK, #BAD, Can't receive aid (healing/armor), can be cleared still (thermostat icn)
	SLOW, #BAD, Cooldown is slow (snail icon)
	ARMOR, #GOOD, Prevents damage for duration 
	HEALTHY, #GOOD, Restores 1 health every second for a period of time (up arrow)
	JUICED, #GOOD, Cooldown is fast (lightning bolt)
}
#Effects are cleared when a monster gets defeated or the time elapses, they shouldn't process unless there is a monster with health
#Effects inflicted by weapons last for primary damage (calc heal) in seconds

const _bad_effects = [effects.STUN,effects.DOT,effects.FEAR
					,effects.WEAK,effects.MUTE,effects.BLIND,
					effects.SICK,effects.SLOW,]

const _good_effects = [effects.ARMOR,effects.HEALTHY,effects.JUICED]

var max_health : int = 5
@export var health : int = 5
@export var current_effects : Dictionary = {} #effect:time until clear
@export var immunity : Array[effects] = []

func setup(maxh : int):
	max_health = maxh
	health = maxh

func reload():
	health = max_health
	current_effects.clear()

func _damage(amt : int):
	if amt < 0: 
		_heal(amt)
		return
	health -= amt
	health = clampi(health,0,max_health)

func _heal(amt : int):
	if amt < 0:
		_damage(amt)
		return
	health += amt
	health = clampi(health,0,max_health)

func process_current(delta):
	for e in current_effects:
		current_effects[e] -= delta
		if current_effects[e] <= 0:
			remove_effect(e)
		else : process_effect(e)

func remove_effect(e : effects):
	current_effects.erase(e)

func add_effect(e : effects, duration : float):
	if e == effects.NONE: return
	if immunity.has(e): duration /= 2.0
	if duration < 1.0: return #TOO SHORT
	if current_effects.has(e): current_effects[e] += duration
	else: current_effects[e] = duration

func process_effect(e : effects):
	match e:
		effects.DOT: _DOT()
		effects.HEALTHY: _HEALTHY()

signal DOT
signal HLTY
var drun := false
func _DOT():
	if drun: return
	drun = true
	if current_effects[effects.DOT] >= 1.0:
		await App.time_delay(1)
		
		if health > 0:
			health -= 1
		DOT.emit()
	drun = false

var hrun := false
func _HEALTHY():
	if hrun: return
	hrun = true
	if current_effects[effects.HEALTHY] >= 1.0:
		await App.time_delay(1)
		
		if health < max_health:
			health += 1
		HLTY.emit()
	hrun = false
