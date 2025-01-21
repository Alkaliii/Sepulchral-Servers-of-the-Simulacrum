extends phaseSpecialOption
class_name pushSpecial

#pushes player away from monster
@export var length : float = 3.0

func perform_special(monster : system_monster_controller):
	#host will push player and player on other instances using RPC?
	var p = monster.get_tree().get_first_node_in_group("player")
	cancel = false
	
	var dur = length
	monster.sync_drag(true,monster.get_path(),-30)
	while true:
		if dur <= 0: break
		if cancel: 
			monster.sync_drag(false)
			return
		p.drag(monster.global_position,-30)
		dur -= monster.get_process_delta_time()
		await App.process_frame()
	
	monster.sync_drag(false)
	special_complete.emit(self)
