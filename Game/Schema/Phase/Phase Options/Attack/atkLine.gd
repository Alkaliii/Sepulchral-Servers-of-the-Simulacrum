extends phaseAttackOption
class_name lineAttack

#spawns attacks down defined vectors, define vectors (can originate from game object), define line length
#on client a specific position must be provided, the client will not derive one. Only the host will

enum ld { #LINE DIR (Line is drawn from spawn to this)
	POS,
	GAME_OBJECT,
	RANDPOS,
}

@export_group("Line Specific Options")
# Pattern A
@export var derive_dir : ld = ld.GAME_OBJECT
@export var to_object_position : phaseAttackOption.s = phaseAttackOption.s.RANDOM_PLAYER
@export var to_position : Vector2 = Vector2(1,0)
## Offset line by this amount in degrees
@export var rotational_offset : float = 0.0

# Pattern B
@export var attack_number : int = 6
@export var grow_factor : float = 1.0 #overrides radius if != 1.0
@export var bifurcate : bool = false

# Spawning
## negative means no delay, zero means frame delay
@export var intra_spawn_delay : float = 0.0
@export var shuffle_spawn_order : bool = false

func attack(_monster : system_monster_controller, _as_client : Dictionary = {}):
	_condition_augment(_monster)
	
	var l
	var growth_index = 1
	for p in _get_spawn_position(_monster):
		l = line(p, _monster)
		if shuffle_spawn_order and !bifurcate: l.shuffle()
		for i in l:
			var line_point_idx = l.find(i)
			var new = DAMAGE_RADIUS.instantiate()
			new.settings = _get_settings(line_point_idx).duplicate()
			if grow_factor != 1.0 and line_point_idx != 0: #need to % for bifurcate
				if line_point_idx % 2 == 0 and bifurcate:
					new.settings.radius = new.settings.radius * (grow_factor * (growth_index))
					growth_index += 1
				else:
					new.settings.radius = new.settings.radius * (grow_factor * (growth_index))
					if !bifurcate: growth_index += 1
			
			_monster.get_parent().add_child(new)
			new.top_level = true
			new.global_position = i
			new.warn()
			
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


func line(origin : Vector2, _m : system_monster_controller) -> Array[Vector2]:
	var dir : Vector2 = Vector2(1,0)
	var tp : Vector2 = to_position
	var points : Array[Vector2] = [origin]
	if derive_dir == ld.GAME_OBJECT: tp = _get_spawn_position_raw(_m, to_object_position).pick_random()
	elif derive_dir == ld.RANDPOS: tp = Vector2.from_angle(randf_range(0, TAU))
	
	dir = (tp - origin).rotated(deg_to_rad(rotational_offset)).normalized()
	
	var inital_radius = _get_settings(0).radius
	var corrected_radius = distance_to_ellipse_edge(inital_radius * 2.0, inital_radius, dir.x, dir.y)
	
	var last_point = origin
	var last_radius = corrected_radius
	for i in attack_number - 1:
		var new_point : Vector2 = last_point
		var add : Vector2 = Vector2.ZERO
		if grow_factor != 1.0:
			add.x = dir.x * ((last_radius / 2.0) + ((corrected_radius * (grow_factor * (i + 1))) / 2.0))
			add.y = dir.y * ((last_radius / 2.0) + ((corrected_radius * (grow_factor * (i + 1))) / 2.0))
			new_point += add
			last_radius = corrected_radius * (grow_factor * (i + 1))
		else: 
			add.x = dir.x * corrected_radius
			add.y = dir.y * corrected_radius
			new_point += add
		
		points.append(new_point)
		last_point = new_point
	
	if bifurcate: points = bifurcate_points(points)
	
	return points

func bifurcate_points(points : Array[Vector2]) -> Array[Vector2]:
	var new_set : Array[Vector2] = []
	for p in points:
		var np = p * -1
		new_set.append(p)
		new_set.append(np)
	
	new_set.pop_front()
	
	return new_set


# Written by the one and only chatGPT ;-; (it was just elipise math...)
func distance_to_ellipse_edge(rx: float, ry: float, vx: float, vy: float) -> float:
	# Semi-major and semi-minor axes
	var a = rx
	var b = ry
	
	# Vector magnitude
	var magnitude = sqrt(vx * vx + vy * vy)
	
	# Calculate distance to edge
	var d = magnitude / sqrt((vx * vx) / (a * a) + (vy * vy) / (b * b))
	
	return d
