extends Resource
class_name phaseSpecialOption

signal special_complete

var cancel : bool = false

func perform_special(monster : system_monster_controller):
	#called constantly while phase is active?, use monster to get player
	pass
