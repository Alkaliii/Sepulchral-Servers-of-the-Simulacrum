extends Resource
class_name DamageRadiusSettings

@export var dmg : int = 1
#bosses only deal a lot of damage on BIG ONES
@export var radius : int = 180
@export var inflict : system_status.effects

@export_group("Timing")
@export var pre_warn : float = 0.5
#time given before area activates

@export var warn_activation_time : float = 1.0
@export var dmg_activation_time : float = 0.5
#time it takes for hazard to grow to full size

@export var hold_time : float = 0.1
#how long the attack remains, walking into it during this time will hurt you

@export var repeat : int = 1
#instead of removing, it will shrink and then it will activate again for n amount of times

@export_group("Field Properties")
@export var slow : bool = false
#Reduce player speed if they are inside it

@export var prevent_attack : bool = false
#Prevent player from attacking if they are inside it

@export var invert_controls : bool = false

@export_group("Movement") #TODO write implementation in tscn
enum mt {
	NONE, #won't move
	ORBIT, #will orbit defined position
	PUSH, #will move away from defined position in the direction found by the difference between it and the position
	PULL, #will move away from defined position in the direction found by the difference between it and the position
	ORTHO_WIGGLE, #moves back and forth perpandicular to the vector derived from global_position - movement_origin, skewed for perspective
	LATERAL_WIGGLE, #like ortho but not rotated
}
@export var movement_type : mt = mt.NONE
var movement_origin : Vector2 = Vector2.ZERO #position in global space to calculate movement with
@export var movement_speed : float = 5.0 #how fast the dr moves
var movement_offset : float = 0.0
var movement_radius : float = 0.0

@export_group("Sound")
enum sfx {
	NONE,
	ACID,
	ICE,
	LIGHTNING
}
@export var spawn_sound : sfx = sfx.ACID

func serialize() -> Dictionary:
	var sset : Dictionary = {}
	
	sset["dmg"] = dmg
	sset["radius"] = radius
	sset["inflict"] = inflict
	sset["pre_warn"] = pre_warn
	sset["warn_activation_time"] = warn_activation_time
	sset["dmg_activation_time"] = dmg_activation_time
	sset["hold_time"] = hold_time
	sset["repeat"] = repeat
	sset["slow"] = slow
	sset["prevent_attack"] = prevent_attack
	sset["invert_controls"] = invert_controls
	sset["movement_type"] = movement_type
	sset["movement_origin"] = var_to_str(movement_origin)
	sset["movement_speed"] = movement_speed
	sset["movement_offset"] = movement_offset
	sset["movement_radius"] = movement_radius
	sset["spawn_sound"] = spawn_sound
	
	return sset

func deserialize(sset : Dictionary):
	dmg = sset["dmg"]
	radius = sset["radius"]
	inflict = sset["inflict"]
	pre_warn = sset["pre_warn"]
	warn_activation_time = sset["warn_activation_time"]
	dmg_activation_time = sset["dmg_activation_time"]
	hold_time = sset["hold_time"]
	repeat = sset["repeat"]
	slow = sset["slow"]
	prevent_attack = sset["prevent_attack"]
	invert_controls = sset["invert_controls"]
	movement_type = sset["movement_type"]
	movement_origin = str_to_var(sset["movement_origin"])
	movement_speed = sset["movement_speed"]
	movement_offset = sset["movement_offset"]
	movement_radius = sset["movement_radius"]
	spawn_sound = sset["spawn_sound"]
