extends phaseAttackOption
class_name circleAttack

@export_group("Circle Specific Options")
## Resolution of the circle pattern
@export var attack_points : int = 6
@export var radius : float = 200
## negative means no delay, zero means frame delay
@export var intra_spawn_delay : float = 0.0
@export var shuffle_spawn_order : bool = false

#spawns attacks in a circle around position, define position (can be game object), define radius
#on client a specific position must be provided, the client will not derive one. Only the host will

func attack(_monster : system_monster_controller, _as_client : Dictionary = {}):
	_condition_augment(_monster)
	
	var c = circ()
	for p in _get_spawn_position(_monster):
		if shuffle_spawn_order: c.shuffle()
		for i in c:
			var new = DAMAGE_RADIUS.instantiate()
			new.settings = _get_settings(c.find(i)).duplicate()
			new.settings.movement_origin = p
			new.settings.movement_radius = radius
			new.settings.movement_offset = ((c.find(i) + 1) / float(attack_points)) * (2.0*PI)
			_monster.get_parent().add_child(new)
			new.top_level = true
			new.global_position = i + p
			new.warn()
			if Plyrm.connected: sync_attack(new.global_position,new.settings)
			
			my_radi.append(new)
			new.finished.connect(_on_damage_finished)
			
			if intra_spawn_delay < 0.0: pass
			elif intra_spawn_delay == 0.0:
				await App.process_frame()
			else:
				await App.time_delay(intra_spawn_delay)
			if cancel: return
	
	_check_complete()
	await App.time_delay(attack_start_delay)
	attack_started.emit(self)


func circ() -> Array[Vector2]:
	var r = radius / 2.0
	var points : int = attack_points
	var poly : Array[Vector2] = []
	for i in points:
		var new = Vector2(1,-1).rotated(deg_to_rad(360) * (i+1)/float(points)) * r
		poly.append(App.isometrize(new))
	
	return poly
