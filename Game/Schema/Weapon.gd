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
	DAGGER, #0% chance to block, 30% to recharge
	SWORD, #10% chance to parry (damage boss instead), 20 to recharge
	STAFF, #0% chance to block, 30% to self heal
	HAMMER, #20% chance to block, 20% to parry
	GLASS, #40% chance to self heal
	AXE, #40% chance to parry
	WARAXE, #20% chance to block, 20% chance to recharge 
	TRIDENT, #50% chance to parry
	BOW, #50% chance to recharge
	BLADE, #50% chance to block 
	GAUNTLET #50% to block,self heal, and recharge
}
#on damage effects: block, parry
#on attack effects: self heal, recharge

@export var icon : i = i.SWORD
@export var primary_damage : wd = wd.D3
@export var secondary_damage : wd = wd.D0
@export var tertiary_damage : wd = wd.D0

@export var inflict_status : system_status.effects = system_status.effects.NONE #flat 15 on light 50 on heavy across all weapons

func on_damage_effect() -> int: #-1 means nothing, 0 means attack was blocked, 1 means it was parried
	match icon:
		i.SWORD: if randf() < 0.1: return 1
		i.HAMMER: 
			if randf() < 0.2: return 1 #parry takes priority
			elif randf() < 0.2: return 0
		i.AXE: if randf() < 0.4: return 1
		i.WARAXE: if randf() < 0.2: return 0
		i.TRIDENT: if randf() < 0.5: return 1
		i.BLADE: if randf() < 0.5: return 0
		i.GAUNTLET: if randf() < 0.5: return 0
	return -1

func on_attack_effect() -> int: #-1 means nothing, 0 means self heal, 1 means recharge
	match icon:
		i.DAGGER: if randf() < 0.3: return 1
		i.SWORD: if randf() < 0.2: return 1
		i.STAFF: if randf() < 0.3: return 0
		i.GLASS: if randf() < 0.4: return 0
		i.WARAXE: if randf() < 0.2: return 1
		i.BOW: if randf() < 0.5: return 1
		i.GAUNTLET:
			if randf() < 0.5: return 1 #recharge takes priority
			elif randf() < 0.5: return 0
	return -1


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

func _get_dice_average(weapon_damage : wd) -> float:
	match weapon_damage:
		wd.D0: return 0.0
		wd.D3: return (1.0+2.0+3.0)/3.0
		wd.D4: return (1.0+2.0+3.0+4.0)/4.0
		wd.D5: return (1.0+2.0+3.0+4.0+5.0)/5.0
		wd.D6: return (1.0+2.0+3.0+4.0+5.0+6.0)/6.0
		wd.D7: return (1.0+2.0+3.0+4.0+5.0+6.0+7.0)/7.0
		wd.D8: return (1.0+2.0+3.0+4.0+5.0+6.0+7.0+8.0)/8.0
		wd.D9: return (1.0+2.0+3.0+4.0+5.0+6.0+7.0+8.0+9.0)/9.0
		wd.D10: return (1.0+2.0+3.0+4.0+5.0+6.0+7.0+8.0+9.0+10.0)/10.0
		wd.D20: return (1.0+2.0+3.0+4.0+5.0+6.0+7.0+8.0+9.0+10.0+11.0+12.0+13.0+14.0+15.0+16.0+17.0+18.0+19.0+20.0)/20.0
	return 0

func get_average() -> float:
	var final : float = 3.0
	final += _get_dice_average(primary_damage)
	final += _get_dice_average(secondary_damage)
	final += _get_dice_average(tertiary_damage)
	return final

func get_heavy_average() -> float:
	var light : float = get_average()
	var final : float = (float(light) + 5.0) * 5.0
	final -= _get_dice_average(primary_damage)
	return final

func dmg_rating() -> int:
	return primary_damage + secondary_damage + tertiary_damage

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

func get_stats_string() -> String:
	var final = ""
	
	if primary_damage != wd.D0:
		var first_slash = "" if secondary_damage == wd.D0 else "/"
		final += str(wd.keys()[primary_damage],first_slash).replace("D","")
	if secondary_damage != wd.D0:
		var second_slash = "" if tertiary_damage == wd.D0 else "/"
		final += str(wd.keys()[secondary_damage],second_slash).replace("D","")
	if tertiary_damage != wd.D0:
		final += str(wd.keys()[tertiary_damage]).replace("D","")
	
	if inflict_status != system_status.effects.NONE:
		final += "!"
	
	return final
