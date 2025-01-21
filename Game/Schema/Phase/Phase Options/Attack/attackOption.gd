extends Resource
class_name phaseAttackOption

enum s { #SPAWN
	BOSS,
	RANDOM_PLAYER,
	ALL_PLAYER,
	#GLOBAL_POSITION, #bad
	#POSITION_FROM_BOSS, #this is offset
	#POSITION_FROM_RANDOM_PLAYER, #this is offset
	POSITION_BETWEEN_BOSS_AND_PLAYER,
	GROUP_OBJECT, #Attack will spawn on a random object in the "spawn" group
	ALL_GROUP_OBJECT, #Attack will spawn on all objects in "spawn" group
}

signal attack_started
#signalled x amt of time after all attacks are spawned (must be emiited before another phase attack is spawned)

signal attack_complete
#signalled when all attacks have freed

@export var spawn_position : s = s.BOSS
@export var spawn_position_offset : Vector2 = Vector2.ZERO
@export var damage_settings : Array[DamageRadiusSettings] = []
#if multiple, each DR spawned will iterate or pick random

enum fmds { #FOR MULTIPLE DAMAGE SETTINGS
	ITERATE,
	RANDOM,
}

@export var multi_ds_behaviour : fmds = fmds.ITERATE
@export var attack_start_delay : float = 1.0

const DAMAGE_RADIUS = preload("res://Game/damage_radius.tscn")

var my_phase : Phase
#parent phase, use to check condition?

var my_radi : Array[Area2D] = []

var cancel : bool = false

func attack(_monster : system_monster_controller, _as_client : Dictionary = {}):
	#Spawn an attack when called
	#Use monster to get player positions
	pass

func sync_attack(position : Vector2, settings : DamageRadiusSettings):
	var data : Array = []
	var drs = JSON.stringify(settings.serialize())
	data.append(position)
	data.append(drs)
	
	Plyrm.Playroom.RPC.call("spawn_dmg",var_to_str(data),Plyrm.Playroom.RPC.Mode.OTHERS)

func _check_complete():
	while true:
		await App.process_frame()
		if my_radi.is_empty():
			break
		
		if !my_phase.is_active: pass #return here
		await App.process_frame()
	
	attack_complete.emit(self)

func _on_damage_finished(d : Area2D):
	my_radi.erase(d)

func _get_settings(idx : int) -> DamageRadiusSettings:
	match multi_ds_behaviour:
		fmds.ITERATE:
			return damage_settings[idx % damage_settings.size()]
		fmds.RANDOM:
			return damage_settings.pick_random()
	return damage_settings[0]

func _condition_augment(_m : system_monster_controller):
	cancel = false
	var d_up : int = 0
	var infl : system_status.effects = system_status.effects.NONE
	for c in my_phase.CONDITION_OPTIONS:
		d_up += c.damage_increase(_m.monster_weapon)
		if c.get_afflication() != system_status.effects.NONE:
			infl = c.get_afflication()
	
	for a in damage_settings:
		a.dmg += d_up
		a.inflict = infl

func _get_spawn_position(_m : Node2D) -> Array[Vector2]:
	#print("getting positions!")
	var pos : Array[Vector2] = []
	match spawn_position:
		s.BOSS: pos.append(_m.global_position)
		s.RANDOM_PLAYER:
			var p : Array = _m.get_tree().get_nodes_in_group("player")
			p.append_array(_m.get_tree().get_nodes_in_group("puppet"))
			
			pos.append(p.pick_random().global_position)
		s.ALL_PLAYER:
			var p : Array = _m.get_tree().get_nodes_in_group("player")
			p.append_array(_m.get_tree().get_nodes_in_group("puppet"))
			
			for plyr in p:
				pos.append(plyr.global_position)
		s.POSITION_BETWEEN_BOSS_AND_PLAYER:
			var p : Array = _m.get_tree().get_nodes_in_group("player")
			p.append_array(_m.get_tree().get_nodes_in_group("puppet"))
			
			var plyr = p.pick_random()
			var position = (_m.global_position + plyr.global_position) / 2.0
			pos.append(position)
		s.GROUP_OBJECT:
			var g = _m.get_tree().get_nodes_in_group("spawn")
			if g.is_empty():
				pos.append(Vector2.ZERO)
			else:
				pos.append(g.pick_random().global_position)
		s.ALL_GROUP_OBJECT:
			var g = _m.get_tree().get_nodes_in_group("spawn")
			if g.is_empty():
				pos.append(Vector2.ZERO)
			else:
				for o in g:
					pos.append(o.global_position)
	
	for p in pos:
		p += spawn_position_offset
	
	return pos

func _get_spawn_position_raw(_m : Node2D, go : s) -> Array[Vector2]:
	#print("getting positions!")
	var pos : Array[Vector2] = []
	match go:
		s.BOSS: pos.append(_m.global_position)
		s.RANDOM_PLAYER:
			var p : Array = _m.get_tree().get_nodes_in_group("player")
			p.append_array(_m.get_tree().get_nodes_in_group("puppet"))
			
			pos.append(p.pick_random().global_position)
		s.ALL_PLAYER:
			var p : Array = _m.get_tree().get_nodes_in_group("player")
			p.append_array(_m.get_tree().get_nodes_in_group("puppet"))
			
			for plyr in p:
				pos.append(plyr.global_position)
		s.POSITION_BETWEEN_BOSS_AND_PLAYER:
			var p : Array = _m.get_tree().get_nodes_in_group("player")
			p.append_array(_m.get_tree().get_nodes_in_group("puppet"))
			
			var plyr = p.pick_random()
			var position = (_m.global_position + plyr.global_position) / 2.0
			pos.append(position)
		s.GROUP_OBJECT:
			var g = _m.get_tree().get_nodes_in_group("spawn")
			if g.is_empty():
				pos.append(Vector2.ZERO)
			else:
				pos.append(g.pick_random().global_position)
		s.ALL_GROUP_OBJECT:
			var g = _m.get_tree().get_nodes_in_group("spawn")
			if g.is_empty():
				pos.append(Vector2.ZERO)
			else:
				for o in g:
					pos.append(o.global_position)
	
	return pos
