extends phaseSpecialOption
class_name pullSpecial

#pulls player toward monster
@export var length : float = 3.0
@export_range(1,99) var strength : float = 1.0

func perform_special(monster : system_monster_controller):
	#host will push player and player on other instances using RPC?
	var p = monster.get_tree().get_first_node_in_group("player")
	cancel = false
	
	var dur = length
	monster.sync_drag(true,monster.get_path(),30 * strength)
	monster.pull(true, 1.0 + (strength / 10.0))
	while true:
		if dur <= 0: break
		if cancel:
			if is_instance_valid(monster):
				monster.pull(false)
				monster.sync_drag(false)
			return
		if p: p.drag(monster.global_position,30 * strength)
		dur -= monster.get_process_delta_time()
		await App.process_frame()
	
	monster.pull(false)
	monster.sync_drag(false)
	special_complete.emit(self)
