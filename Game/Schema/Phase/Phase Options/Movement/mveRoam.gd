extends phaseMovementOption
class_name roamMove

#moves to a random position around ZERO ZERO, define speed, random limits

@export var roam_limit : Vector2 = Vector2(200,200)
@export var roam_speed : float = 10
@export var move_ease : Tween.EaseType = Tween.EaseType.EASE_IN_OUT
@export var move_trans : Tween.TransitionType = Tween.TransitionType.TRANS_QUAD

var d = 0.0
func move(monster : system_monster_controller):
	cancel_movement()
	mTween = monster.create_tween()
	
	var roam_speeddd = roam_speed
	var npos : Vector2 = monster.check_position(randpos())
	if monster.halfway_dead: roam_speeddd *= 4.0
	var spd = (monster.global_position - npos).length() / roam_speeddd
	
	mTween.tween_property(self,"d",1.0,spd).set_ease(move_ease).set_trans(move_trans)
	var idx = 0.0
	monster.stare((npos - monster.global_position))
	while true:
		if !mTween: break
		if idx >= spd: break
		if App.get_tree().paused: 
			await App.process_frame()
			continue
		if !is_instance_valid(monster): return
		monster.velocity = lerp(monster.velocity,(npos - monster.global_position).normalized() * roam_speeddd,0.5)
		monster.move_and_slide()
		await App.process_frame()
		idx += App.get_process_delta_time()
	
	#mTween.tween_property(monster,"global_position",npos,spd).set_ease(move_ease).set_trans(move_trans)
	#await mTween.finished
	#monster.global_position = npos
	movement_complete.emit(self)

func randpos() -> Vector2:
	var rpos : Vector2 = Vector2.ZERO
	
	rpos.x = randf_range(-roam_limit.x,roam_limit.x)
	rpos.y = randf_range(-roam_limit.y,roam_limit.y)
	
	return rpos
