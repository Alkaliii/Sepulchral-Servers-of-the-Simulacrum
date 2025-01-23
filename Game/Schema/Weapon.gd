extends Resource
class_name system_weapon

enum wd {
	D0,
	D3,
	D4,
	D5,
	D6,
	D7,
	D8,
	D9,
	D10,
	D20,
}

enum i {
	DAGGER,
	SWORD,
	STAFF,
	HAMMER,
	GLASS,
	AXE,
	WARAXE,
	TRIDENT,
	BOW,
	BLADE,
	GAUNTLET
}

@export var icon : i = i.SWORD
@export var primary_damage : wd = wd.D3
@export var secondary_damage : wd = wd.D0
@export var tertiary_damage : wd = wd.D0

@export var inflict_status : system_status.effects = system_status.effects.NONE #flat 15 on light 50 on heavy across all weapons

func calc_damage(base : int) -> int:
	var final : int = base
	final += roll(primary_damage)
	final += roll(secondary_damage)
	final += roll(tertiary_damage)
	return final

func calc_heavy_damage(base : int, scache : float) -> int:
	var light : int = calc_damage(base)
	var final : int = int(ceil((float(light) + scache) * scache))
	final -= roll(primary_damage)
	return final

func calc_heal(base : int) -> int:
	var final : int = base
	final += roll(primary_damage)
	return final

func calc_inflict(base : int,c : int) -> Array:
	var final : Array = [system_status.effects.NONE,0.0]
	match c:
		0: #light
			if randf_range(0,100) < 15:
				final[0] = inflict_status
				final[1] = calc_heal(base) #lazy time calc
		1: #heavy
			if randf_range(0,100) < 50:
				final[0] = inflict_status
				final[1] = calc_heal(base)
	return final

func roll(weapon_damage : wd) -> int:
	match weapon_damage:
		wd.D0: return 0
		wd.D3: return randi_range(1,3)
		wd.D4: return randi_range(1,4)
		wd.D5: return randi_range(1,5)
		wd.D6: return randi_range(1,6)
		wd.D7: return randi_range(1,7)
		wd.D8: return randi_range(1,8)
		wd.D9: return randi_range(1,9)
		wd.D10: return randi_range(1,10)
		wd.D20: return randi_range(1,20)
	return 0

const p_damage_weight = [0.0,2.0,1.0,1.0,0.5,0.5,0.5,0.5,0.25,0.24]
const st_damage_weight = [1.0,1.0,1.0,1.0,0.5,0.5,0.5,0.5,0.25,0.24]
const is_weight = [3.0,0.5,0.5]
const icon_weights = [0.5,1.0,1.0,0.75,0.75,1.0,0.75,0.25,0.5,0.5,0.24]
const weapon_is = [
	system_status.effects.NONE,
	system_status.effects.STUN,
	system_status.effects.DOT,
]
func generate_random():
	var damage_options = wd.keys()
	var rand : RandomNumberGenerator = RandomNumberGenerator.new()
	rand.randomize()
	icon = i[i.keys()[rand.rand_weighted(icon_weights)]]
	
	primary_damage = wd[damage_options[rand.rand_weighted(p_damage_weight)]]
	secondary_damage = wd[damage_options[rand.rand_weighted(st_damage_weight)]]
	if secondary_damage != wd.D0:
		tertiary_damage = wd[damage_options[rand.rand_weighted(st_damage_weight)]]
		inflict_status = weapon_is[rand.rand_weighted(is_weight)]
	else: 
		tertiary_damage = wd.D0
		inflict_status = system_status.effects.NONE
	
	var data = {
		"icon": i.keys()[icon],
		"pdmg": wd.keys()[primary_damage],
		"sdmg": wd.keys()[secondary_damage],
		"tdmg": wd.keys()[tertiary_damage],
		"inflict": system_status.effects.keys()[inflict_status]
	}
	
	print(data)
