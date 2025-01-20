extends phaseSpecialOption
class_name pullSpecial

#pulls player toward monster
@export var length : float = 3.0

func perform_special(monster : Node2D):
	#host will push player and player on other instances using RPC?
	var p = monster.get_tree().get_first_node_in_group("player")
	cancel = false
	
	var dur = length
	while true:
		if dur <= 0: break
		if cancel: return
		p.drag(monster.global_position,30)
		dur -= monster.get_process_delta_time()
		await App.process_frame()
	
	special_complete.emit(self)
