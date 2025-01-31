extends Resource
class_name system_job

enum j {
	## Charge by 1, Max 3, Mid Damage (2)
	## Health starts at 5
	## Not intended to be used beyond tutorial
	JOBLESS,
	
	## Charge by 1, Max 6, High Damage (3)
	## Health starts at 7
	## Can left click on players to give armor effect
	KNIGHT,
	
	## Charge by 3, Max 3, Low Damage (1)
	## Health starts at 6
	## Can left click on players to remove bad effects
	MAGE,
	
	## Charge by 2, Max 4, Low Damage (1)
	## Health starts at 4
	## Can left click on players to heal them
	SAINT,
	
	#Advanced Jobs
	## Charge by 2, Max 6, High Damage (3)
	## Health starts at 8
	## Left click on players will clear and give armor effect
	MAGIC_KNIGHT, #Mage + Knight
	
	## Charge by 4, Max 4, Mid Damage (2)
	## Health starts at 8
	## Left click on players will heal and clear
	DIVINE_SAGE, #Mage + Saint
	
	## Charge by 2, Max 6, High Damage (3)
	## Health starts at 8
	## Left click will heal and give armor effect
	HIGH_PALADIN, #Saint + Knight
	
	## Charge by 2, Max 8, Extra High Damage (4)
	## Health starts at 7
	## Left click will give armor effect
	GUARDIAN, #Knight + Knight
	
	## Charge by 5, Max 5, Mid Damage (2)
	## Health starts at 7
	## Left click will clear bad effects
	SIBYL, #Mage + Mage
	
	## Charge by 3, Max 6, Mid Damage (2)
	## Health starts at 7
	## Left click will heal
	ORACLE, #Saint + Saint
	
	#Weird Jobs!?
	LEGIONNAIRE, #Abnormal Knight
	ARCANE_MYSTIC, #Abnormal Mage
	OCCULT_PSYCHIC, #Abnormal Saint
}

@export var JOB : j = j.JOBLESS
@export var additional_health : int = 0
@export var additional_max_pcache : int = 0
@export var additional_pcache_charge_amt : int = 0
@export var additional_damage : int = 0

@export var can_guard : bool = false
@export var can_clear : bool = false
@export var can_heal : bool = false
@export var need_sight : bool = false #clicks only validate if a raycast can be drawn from player to subject

var m_pc : int = 3
var pc_c : int = 1
var health : int = 5
var base_dmg : int = 2

var final_m_pc : int
var final_pc_c : int
var final_health : int
var final_base_dmg : int

func setup():
	can_guard = false
	can_clear = false
	can_heal = false
	need_sight = false
	match JOB:
		j.JOBLESS:
			m_pc = 3
			pc_c = 1
			health = 5
			base_dmg = 2
		j.KNIGHT:
			m_pc = 6
			pc_c = 1
			health = 7
			base_dmg = 3
			can_guard = true
			need_sight = true
		j.MAGE:
			m_pc = 3
			pc_c = 3
			health = 6
			base_dmg = 1
			can_clear = true
		j.SAINT:
			m_pc = 4
			pc_c = 2
			health = 4
			base_dmg = 1
			can_heal = true
		j.MAGIC_KNIGHT:
			m_pc = 6
			pc_c = 2
			health = 8
			base_dmg = 3
			can_guard = true
			can_clear = true
			need_sight = true
		j.DIVINE_SAGE:
			m_pc = 4
			pc_c = 4
			health = 8
			base_dmg = 2
			can_clear = true
			can_heal = true
		j.HIGH_PALADIN:
			m_pc = 6
			pc_c = 2
			health = 8
			base_dmg = 3
			can_guard = true
			can_heal = true
		j.GUARDIAN:
			m_pc = 8
			pc_c = 2
			health = 7
			base_dmg = 4
			can_guard = true
			need_sight = true
		j.SIBYL:
			m_pc = 5
			pc_c = 5
			health = 7
			base_dmg = 2
			can_clear = true
			need_sight = true
		j.ORACLE:
			m_pc = 6
			pc_c = 3
			health = 7
			base_dmg = 2
			can_heal = true
			need_sight = true
		j.LEGIONNAIRE:
			m_pc = 6
			pc_c = 1
			health = 8
			base_dmg = 2
			can_clear = true
			need_sight = true
		j.ARCANE_MYSTIC:
			m_pc = 3
			pc_c = 3
			health = 5
			base_dmg = 3
			can_heal = true
		j.OCCULT_PSYCHIC:
			m_pc = 4
			pc_c = 2
			health = 4
			base_dmg = 4
			can_guard = true
	
	final_m_pc = m_pc + additional_max_pcache
	final_pc_c = pc_c + additional_pcache_charge_amt
	final_health = health + additional_health
	final_base_dmg = base_dmg + additional_damage

static func get_info(key : j) -> Dictionary:
	var info : Dictionary = {
		"name": str(j.keys()[key]).replace("_"," "),
		"desc":"",
		"bhealth":5,
		"bdamage":2,
		"malloc":1,
		"cache":3,
	}
	
	match key:
		j.JOBLESS:
			info.desc = "No dedicated methods or functions."
		j.KNIGHT:
			info.bhealth = 7
			info.bdamage = 3
			info.malloc = 1
			info.cache = 6
			info.desc = "Click on yourself or others to prevent damage!"
		j.MAGE:
			info.bhealth = 6
			info.bdamage = 1
			info.malloc = 3
			info.cache = 3
			info.desc = "Click on yourself or others to cure bad status effects!"
		j.SAINT:
			info.bhealth = 4
			info.bdamage = 1
			info.malloc = 2
			info.cache = 4
			info.desc = "Click on yourself or others to regain health!"
		j.MAGIC_KNIGHT:
			info.bhealth = 8
			info.bdamage = 3
			info.malloc = 2
			info.cache = 6
			info.desc = "Click on yourself or others to cure bad status effects and prevent damage!"
		j.DIVINE_SAGE:
			info.bhealth = 8
			info.bdamage = 2
			info.malloc = 4
			info.cache = 4
			info.desc = "Click on yourself or others to regain health and cure bad status effects!"
		j.HIGH_PALADIN:
			info.bhealth = 8
			info.bdamage = 3
			info.malloc = 2
			info.cache = 6
			info.desc = "Click on yourself or others to regain health and prevent damage!"
		j.GUARDIAN:
			info.bhealth = 7
			info.bdamage = 4
			info.malloc = 2
			info.cache = 8
			info.desc = "Click on yourself or others to prevent damage!"
		j.SIBYL:
			info.bhealth = 7
			info.bdamage = 2
			info.malloc = 5
			info.cache = 5
			info.desc = "Click on yourself or others to cure bad status effects!"
		j.ORACLE:
			info.bhealth = 7
			info.bdamage = 2
			info.malloc = 3
			info.cache = 6
			info.desc = "Click on yourself or others to regain health!"
		j.LEGIONNAIRE:
			info.bhealth = 8
			info.bdamage = 2
			info.malloc = 1
			info.cache = 6
			info.desc = "Click on yourself or others to cure bad status effects!"
		j.ARCANE_MYSTIC:
			info.bhealth = 5
			info.bdamage = 3
			info.malloc = 3
			info.cache = 3
			info.desc = "Click on yourself or others to regain health!"
		j.OCCULT_PSYCHIC:
			info.bhealth = 4
			info.bdamage = 4
			info.malloc = 2
			info.cache = 4
			info.desc = "Click on yourself or others to prevent damage!"
	
	return info
