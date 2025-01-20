extends phaseMovementOption
class_name roamMove

#moves to a random position around ZERO ZERO, define speed, random limits

@export var roam_limit : Vector2 = Vector2(200,200)
@export var roam_speed : float = 10
@export var move_ease : Tween.EaseType = Tween.EaseType.EASE_IN_OUT
@export var move_trans : Tween.TransitionType = Tween.TransitionType.TRANS_QUAD

func move(monster : system_monster_controller):
	cancel_movement()
	mTween = monster.create_tween()
	
	var npos : Vector2 = monster.check_position(randpos())
	var spd = (monster.global_position - npos).length() / roam_speed
	
	mTween.tween_property(monster,"global_position",npos,spd).set_ease(move_ease).set_trans(move_trans)
	await mTween.finished
	movement_complete.emit()

func randpos() -> Vector2:
	var rpos : Vector2 = Vector2.ZERO
	
	rpos.x = randf_range(-roam_limit.x,roam_limit.x)
	rpos.y = randf_range(-roam_limit.y,roam_limit.y)
	
	return rpos
