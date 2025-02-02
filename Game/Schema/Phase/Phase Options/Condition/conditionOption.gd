extends Resource
class_name phaseConditionOption

enum c {
	NORMAL, #all attacks validate no status is inflicted
	LIGHT_ONLY, #only light attacks validate
	HEAVY_ONLY, #only heavy attacks validate
	INVULNERABLE, #no attacks validate, status damage still applies
}

@export var condition : c = c.NORMAL
@export var inflict : system_status.effects = system_status.effects.NONE
@export var is_clutch : bool = false 

func validate_on_condition(click : int) -> bool:
	match condition:
		c.NORMAL: return true
		c.LIGHT_ONLY: return click == 0
		c.HEAVY_ONLY: return click == 1
		c.INVULNERABLE: return false
	return true

func get_afflication() -> system_status.effects:
	return inflict

func damage_increase(weap : system_weapon) -> int:
	if is_clutch:
		return weap.calc_damage(1)
	return 0
