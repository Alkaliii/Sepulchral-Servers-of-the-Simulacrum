extends Resource
class_name phaseMovementOption

signal movement_complete 
#use if a phase has multiple movements to decide when to switch between them

var mTween : Tween

func move(monster : system_monster_controller):
	pass

func cancel_movement(emit : bool = false):
	if mTween: mTween.kill()
	if emit: movement_complete.emit()
