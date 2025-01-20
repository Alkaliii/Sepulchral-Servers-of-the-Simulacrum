extends Resource
class_name phaseConditionOption

func validate_on_condition(click : int) -> bool:
	return true

func get_afflication() -> system_status.effects:
	return system_status.effects.NONE

func damage_increase(weap : system_weapon) -> int:
	return 0
