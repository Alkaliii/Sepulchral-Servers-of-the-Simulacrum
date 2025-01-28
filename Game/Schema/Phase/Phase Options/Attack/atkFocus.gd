extends phaseAttackOption
class_name focusAttack

@export_group("Focus Specific Options")
@export var attack_number : int = 6

# Spawning
## negative means no delay, zero means frame delay
@export var intra_spawn_delay : float = 1.0


func attack(_monster : system_monster_controller, _as_client : Dictionary = {}):
	_condition_augment(_monster)
	
	for i in attack_number:
		var new = DAMAGE_RADIUS.instantiate()
		new.settings = _get_settings(i).duplicate()
		_monster.get_parent().add_child(new)
		new.top_level = true
		new.global_position = _get_spawn_position(_monster).pick_random()
		new.settings.movement_radius = (_monster.global_position-new.global_position).length()
		new.settings.movement_origin = _monster.global_position
		new.settings.movement_offset = ((i+1) / float(attack_number)) * (2.0*PI)
		new.warn()
		if Plyrm.connected: sync_attack(new.global_position,new.settings)
		
		my_radi.append(new)
		new.finished.connect(_on_damage_finished)
		
		if intra_spawn_delay < 0.0: pass
		elif intra_spawn_delay == 0.0:
			await App.process_frame()
		else:
			await App.time_delay((intra_spawn_delay * 0.5) if _monster.halfway_dead else intra_spawn_delay)
		if cancel: return
	
	_check_complete()
	await App.time_delay(attack_start_delay)
	attack_started.emit(self)
