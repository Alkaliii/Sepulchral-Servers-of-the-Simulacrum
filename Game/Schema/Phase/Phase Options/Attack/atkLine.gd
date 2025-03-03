extends phaseAttackOption
class_name lineAttack

#spawns attacks down defined vectors, define vectors (can originate from game object), define line length
#on client a specific position must be provided, the client will not derive one. Only the host will

#Grow on multi object doesn't work

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
#@export var inverse_growth : bool = false
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
		print(p)
		l = line(p, _monster)
		#App.debug_line.emit(l)
		if shuffle_spawn_order: l.shuffle() #and !bifurcate: l.shuffle()
		growth_index = 1
		for i : Vector2 in l:
			var line_point_idx = l.find(i)
			#if line_point_idx != 0: line_point_idx = (l.find(i) - 1) % attack_number
			if line_point_idx == 0: growth_index = 1
			var new = DAMAGE_RADIUS.instantiate()
			new.settings = _get_settings(line_point_idx).duplicate()
			if new.settings.movement_type == DamageRadiusSettings.mt.ORBIT and derive_dir != ld.POS:
				print("no orbit on arbitrary line, (set to derive pos (1,0))")
				new.settings.movement_type = DamageRadiusSettings.mt.NONE
			new.settings.movement_origin = p
			new.settings.movement_radius = (i-p).length()
			new.settings.movement_offset = ((l.find(i) + 1) / l.size()) * (2.0*PI)
			#if grow_factor != 1.0 and line_point_idx != 0: #need to % for bifurcate
				#if line_point_idx % 2 == 0 and bifurcate:
					#new.settings.radius = new.settings.radius * (grow_factor * (growth_index))
					#growth_index += 1
				#else:
			if grow_factor != 1.0 and line_point_idx != 0:
				var gmod = growth_index
				new.settings.radius = new.settings.radius * (grow_factor * (gmod))
				growth_index += 1
					#if !bifurcate: growth_index += 1
			
			if bifurcate and line_point_idx != 0:
				var new2 = DAMAGE_RADIUS.instantiate()
				new2.settings = new.settings.duplicate()
				_monster.get_parent().add_child(new2)
				new2.top_level = true
				new2.global_position = (Vector2(i.x - p.x,i.y - p.y).rotated(deg_to_rad(180.0)) + p)# * Vector2(1.0,0.5) 
				new2.warn()
				if Plyrm.connected: sync_attack(new2.global_position,new2.settings)
				my_radi.append(new2)
				new2.finished.connect(_on_damage_finished)
			
			_monster.get_parent().add_child(new)
			new.top_level = true
			new.global_position = i
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


func line(origin : Vector2, _m : system_monster_controller) -> Array[Vector2]:
	var dir : Vector2 = Vector2(1,0)
	var tp : Array[Vector2] = [to_position]
	var points : Array[Vector2] = [origin]
	
	if derive_dir == ld.GAME_OBJECT: 
		tp = _get_spawn_position_raw(_m, to_object_position)
		if to_object_position in [phaseAttackOption.s.RANDOM_PLAYER,phaseAttackOption.s.POSITION_BETWEEN_BOSS_AND_PLAYER]:
			_m.stare(tp.pick_random() - _m.global_position)
	elif derive_dir == ld.RANDPOS: tp = [Vector2.from_angle(randf_range(0, TAU))]
	
	
	for tpp in tp:
		dir = (tpp - origin).rotated(deg_to_rad(rotational_offset)).normalized()
		
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
	
	#if bifurcate: points = bifurcate_points(points)
	
	return points

func bifurcate_points(points : Array[Vector2]) -> Array[Vector2]:
	var new_set : Array[Vector2] = []
	for p in points:
		var np = p.rotated(deg_to_rad(180))# * -1
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
