extends phaseMovementOption
class_name teleportMove

#moves to defined positions "instantaneously", define positions (or just random)

enum tp {
	RANDOM,
	GLOBAL,
}

@export var teleport_to : tp = tp.RANDOM
@export var tele_global : Vector2 = Vector2.ZERO
@export var tele_limit : Vector2 = Vector2(200,200)
@export var hold : float = 0.5
var m : system_monster_controller

func move(monster : system_monster_controller):
	cancel_movement()
	m = monster
	
	var pos : Vector2
	match teleport_to:
		tp.RANDOM: pos = monster.check_position(randpos())
		tp.GLOBAL: pos = monster.check_position(tele_global)
	
	await monster.disappear(true)
	mTween = monster.create_tween()
	mTween.tween_property(monster,"global_position",pos,hold)
	await mTween.finished
	monster.stare()
	monster.disappear(false)
	
	movement_complete.emit(self)


func cancel_movement(emit : bool = false):
	if m and is_instance_valid(m): m.disappear(false)
	if mTween: mTween.kill()
	if emit: movement_complete.emit(self)

func randpos() -> Vector2:
	var rpos : Vector2 = Vector2.ZERO
	
	rpos.x = randf_range(-tele_limit.x,tele_limit.x)
	rpos.y = randf_range(-tele_limit.y,tele_limit.y)
	
	return rpos
