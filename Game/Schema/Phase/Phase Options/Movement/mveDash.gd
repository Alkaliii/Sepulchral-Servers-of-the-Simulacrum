extends phaseMovementOption
class_name dashMove

#moves to one position via tweening, define the position (possible to target player)
#and by one position I mean player...

@export var dash_speed : float = 1900
@export var move_ease : Tween.EaseType = Tween.EaseType.EASE_OUT
@export var move_trans : Tween.TransitionType = Tween.TransitionType.TRANS_EXPO

var plyr : Node2D

func move(monster : system_monster_controller):
	cancel_movement()
	await App.process_frame()
	mTween = monster.create_tween()
	
	var npos : Vector2 = monster.check_position(get_player(monster).pick_random())
	var spd = (monster.global_position - npos).length() / dash_speed
	var initpos = monster.global_position
	
	mTween.tween_property(monster,"global_position",npos,spd).set_ease(move_ease).set_trans(move_trans)
	await mTween.finished
	
	if (plyr.global_position - monster.global_position).length() < 50:
		plyr.knockback(initpos,2222)

	else: print("Too far to knockback")
	movement_complete.emit(self)

func get_player(_m : system_monster_controller) -> Array[Vector2]:
	var pos : Array[Vector2]
	var p : Array = _m.get_tree().get_nodes_in_group("player")
	p.append_array(_m.get_tree().get_nodes_in_group("puppet"))
	
	if !p.is_empty():
		plyr = p.pick_random()
		pos.append(plyr.global_position)
	else: pos.append(_m.global_position)
	return pos
